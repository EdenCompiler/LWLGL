(in-package #:lwlgl.examples)

(defparameter +instanced-vertex-shader+
"#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aOffset;
out vec3 vColor;
void main() {
  vColor = aColor;
  gl_Position = vec4(aPos * 0.35 + aOffset, 0.0, 1.0);
}")

(defparameter +instanced-fragment-shader+
"#version 330 core
in vec3 vColor;
out vec4 FragColor;
void main() { FragColor = vec4(vColor, 1.0); }")

(defun instanced-triangles (&key max-frames)
  "Draws triangles in one GL 3.3 instanced call; MAX-FRAMES supports smoke tests."
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
    (lwlgl.glfw.glfw34:glfw-with-window (window 900 600 "LWLGL — Instanced Rendering")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.glfw.glfw34:glfw-swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((vao (lwlgl.opengl:make-vertex-array))
            (vertex-vbo (lwlgl.opengl:make-buffer))
            (instance-vbo (lwlgl.opengl:make-buffer))
            (program (lwlgl.opengl:make-program +instanced-vertex-shader+ +instanced-fragment-shader+)))
        (unwind-protect
             (progn
               (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
               (lwlgl.opengl.gl33:gl-bind-buffer
                lwlgl.opengl.gl33:+gl-array-buffer+ vertex-vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl.gl33:+gl-array-buffer+
                #(-0.55 -0.45  1.0 0.25 0.20
                   0.55 -0.45  0.20 1.0 0.35
                   0.00  0.55  0.25 0.45 1.0)
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                0 2 lwlgl.opengl.gl33:+gl-float-type+ 0 20 (cffi:null-pointer))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 0)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                1 3 lwlgl.opengl.gl33:+gl-float-type+ 0 20 (cffi:make-pointer 8))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 1)

               (lwlgl.opengl.gl33:gl-bind-buffer
                lwlgl.opengl.gl33:+gl-array-buffer+ instance-vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl.gl33:+gl-array-buffer+
                #(-0.62 0.45   0.0 0.45   0.62 0.45
                  -0.62 -0.45  0.0 -0.45  0.62 -0.45)
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                2 2 lwlgl.opengl.gl33:+gl-float-type+ 0 8 (cffi:null-pointer))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 2)
               (lwlgl.opengl.gl33:gl-vertex-attrib-divisor 2 1)

               (lwlgl.glfw.glfw34:glfw-set-key-handler
                window (lambda (window key scancode action mods)
                         (declare (ignore scancode mods))
                         (when (and (= key lwlgl.glfw.glfw34:+glfw-key-escape+)
                                    (= action lwlgl.glfw.glfw34:+glfw-press+))
                           (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))
               (let ((frames 0))
                 (lwlgl.glfw.glfw34:glfw-run-loop
                  window
                  (lambda (window)
                    (multiple-value-bind (width height)
                        (lwlgl.glfw.glfw34:glfw-framebuffer-size window)
                      (lwlgl.opengl.gl33:gl-viewport 0 0 width height))
                    (lwlgl.opengl.gl33:gl-clear-color 0.025 0.03 0.045 1.0)
                    (lwlgl.opengl.gl33:gl-clear
                     lwlgl.opengl.gl33:+gl-color-buffer-bit+)
                    (lwlgl.opengl.gl33:gl-use-program program)
                    (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
                    (lwlgl.opengl.gl33:gl-draw-arrays-instanced
                     lwlgl.opengl.gl33:+gl-triangles+ 0 3 6)
                    (when (and max-frames (>= (incf frames) max-frames))
                      (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))))
          (lwlgl.opengl.gl33:gl-delete-program program)
          (lwlgl.opengl:delete-buffer instance-vbo)
          (lwlgl.opengl:delete-buffer vertex-vbo)
          (lwlgl.opengl:delete-vertex-array vao))))))
