(in-package #:lwlgl.examples)

(defparameter +textured-quad-vertex-shader+
"#version 330 core
layout (location = 0) in vec2 aPosition;
layout (location = 1) in vec2 aTexCoord;
out vec2 vTexCoord;
void main() {
  vTexCoord = aTexCoord;
  gl_Position = vec4(aPosition, 0.0, 1.0);
}")

(defparameter +textured-quad-fragment-shader+
"#version 330 core
in vec2 vTexCoord;
uniform sampler2D uTexture;
out vec4 fragmentColor;
void main() {
  fragmentColor = texture(uTexture, vTexCoord);
}")

(defun %checkerboard-rgba (size &optional (cells 8))
  (let ((pixels (make-array (* size size 4) :element-type '(unsigned-byte 8)))
        (cell-size (max 1 (floor size cells))))
    (dotimes (y size pixels)
      (dotimes (x size)
        (let* ((bright-p (evenp (+ (floor x cell-size) (floor y cell-size))))
               (offset (* 4 (+ x (* y size)))))
          (setf (aref pixels offset) (if bright-p 245 25)
                (aref pixels (+ offset 1)) (if bright-p 185 55)
                (aref pixels (+ offset 2)) (if bright-p 45 180)
                (aref pixels (+ offset 3)) 255))))))

(defun textured-quad (&key max-frames)
  "Renders a procedural checkerboard texture without external asset files."
  (lwlgl.glfw.glfw34:glfw-with-glfw ()
    (lwlgl.glfw.glfw34:glfw-default-window-hints)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-context-version-major+ 3)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-context-version-minor+ 3)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-opengl-profile+
     lwlgl.glfw.glfw34:+glfw-opengl-core-profile+)
    #+darwin
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-opengl-forward-compat+
     lwlgl.glfw.glfw34:+glfw-true+)
    (lwlgl.glfw.glfw34:glfw-with-window (window 900 600 "LWLGL — Procedural Texture")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.glfw.glfw34:glfw-swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((vao (lwlgl.opengl:make-vertex-array))
            (vbo (lwlgl.opengl:make-buffer))
            (ebo (lwlgl.opengl:make-buffer))
            (program 0)
            (texture 0))
        (unwind-protect
             (progn
               (setf program
                     (lwlgl.opengl:make-program
                      +textured-quad-vertex-shader+
                      +textured-quad-fragment-shader+))
               (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
               (lwlgl.opengl.gl33:gl-bind-buffer
                lwlgl.opengl.gl33:+gl-array-buffer+ vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl.gl33:+gl-array-buffer+
                #(-0.75 -0.75  0.0 0.0
                   0.75 -0.75  1.0 0.0
                   0.75  0.75  1.0 1.0
                  -0.75  0.75  0.0 1.0)
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-bind-buffer
                lwlgl.opengl.gl33:+gl-element-array-buffer+ ebo)
               (lwlgl.opengl:upload-unsigned-ints
                lwlgl.opengl.gl33:+gl-element-array-buffer+ #(0 1 2 2 3 0)
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                0 2 lwlgl.opengl.gl33:+gl-float-type+ 0 16 (cffi:null-pointer))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 0)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                1 2 lwlgl.opengl.gl33:+gl-float-type+ 0 16 (cffi:make-pointer 8))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 1)
               (let ((pixels (%checkerboard-rgba 64)))
                 (lwlgl.core:with-foreign-array (pointer :unsigned-char pixels)
                   (setf texture
                         (lwlgl.opengl:create-texture-2d
                          64 64 pointer :min-filter lwlgl.opengl.gl33:+gl-nearest+
                          :mag-filter lwlgl.opengl.gl33:+gl-nearest+))))
               (let ((sampler
                       (lwlgl.opengl.gl33:gl-get-uniform-location program "uTexture"))
                     (frames 0))
                 (lwlgl.glfw.glfw34:glfw-set-key-handler
                  window
                  (lambda (window key scancode action mods)
                    (declare (ignore scancode mods))
                    (when (and (= key lwlgl.glfw.glfw34:+glfw-key-escape+)
                               (= action lwlgl.glfw.glfw34:+glfw-press+))
                      (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))
                 (lwlgl.glfw.glfw34:glfw-run-loop
                  window
                  (lambda (window)
                    (multiple-value-bind (width height)
                        (lwlgl.glfw.glfw34:glfw-framebuffer-size window)
                      (lwlgl.opengl.gl33:gl-viewport 0 0 width height))
                    (lwlgl.opengl.gl33:gl-clear-color 0.025 0.03 0.05 1.0)
                    (lwlgl.opengl.gl33:gl-clear
                     lwlgl.opengl.gl33:+gl-color-buffer-bit+)
                    (lwlgl.opengl.gl33:gl-use-program program)
                    (lwlgl.opengl.gl33:gl-uniform-1i sampler 0)
                    (lwlgl.opengl.gl33:gl-active-texture
                     lwlgl.opengl.gl33:+gl-texture0+)
                    (lwlgl.opengl.gl33:gl-bind-texture
                     lwlgl.opengl.gl33:+gl-texture-2d+ texture)
                    (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
                    (lwlgl.opengl.gl33:gl-draw-elements
                     lwlgl.opengl.gl33:+gl-triangles+ 6
                     lwlgl.opengl.gl33:+gl-unsigned-int+ (cffi:null-pointer))
                    (when (and max-frames (>= (incf frames) max-frames))
                      (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))))
          (when (plusp texture) (lwlgl.opengl:delete-texture texture))
          (when (plusp program) (lwlgl.opengl.gl33:gl-delete-program program))
          (lwlgl.opengl:delete-buffer ebo)
          (lwlgl.opengl:delete-buffer vbo)
          (lwlgl.opengl:delete-vertex-array vao))))))
