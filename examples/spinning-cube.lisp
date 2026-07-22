(in-package #:lwlgl.examples)

(defparameter +cube-vertex-shader+
"#version 330 core
layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aColor;
uniform mat4 uMVP;
out vec3 vColor;
void main() {
  vColor = aColor;
  gl_Position = uMVP * vec4(aPosition, 1.0);
}")

(defparameter +cube-fragment-shader+
"#version 330 core
in vec3 vColor;
out vec4 fragmentColor;
void main() {
  fragmentColor = vec4(vColor, 1.0);
}")

(defparameter +cube-vertices+
  #(-1.0 -1.0 -1.0  0.15 0.30 1.00
     1.0 -1.0 -1.0  0.95 0.20 0.25
     1.0  1.0 -1.0  1.00 0.75 0.15
    -1.0  1.0 -1.0  0.25 0.90 0.35
    -1.0 -1.0  1.0  0.20 0.85 0.95
     1.0 -1.0  1.0  0.85 0.25 0.95
     1.0  1.0  1.0  0.95 0.95 0.30
    -1.0  1.0  1.0  0.30 0.55 1.00))

(defparameter +cube-indices+
  #(4 5 6  6 7 4                 ; front
    1 0 3  3 2 1                 ; back
    0 4 7  7 3 0                 ; left
    5 1 2  2 6 5                 ; right
    3 7 6  6 2 3                 ; top
    0 1 5  5 4 0))               ; bottom

(defun spinning-cube (&key max-frames)
  "Renders an indexed, depth-tested spinning cube using GLFW 3.4 and OpenGL 3.3."
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
    (lwlgl.glfw.glfw34:glfw-with-window (window 960 640 "LWLGL 1.0 — Spinning Cube")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.glfw.glfw34:glfw-swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((vao (lwlgl.opengl:make-vertex-array))
            (vbo (lwlgl.opengl:make-buffer))
            (ebo (lwlgl.opengl:make-buffer))
            (program 0))
        (unwind-protect
             (progn
               (setf program
                     (lwlgl.opengl:make-program
                      +cube-vertex-shader+ +cube-fragment-shader+))
               (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
               (lwlgl.opengl.gl33:gl-bind-buffer
                lwlgl.opengl.gl33:+gl-array-buffer+ vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl.gl33:+gl-array-buffer+ +cube-vertices+
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-bind-buffer
                lwlgl.opengl.gl33:+gl-element-array-buffer+ ebo)
               (lwlgl.opengl:upload-unsigned-ints
                lwlgl.opengl.gl33:+gl-element-array-buffer+ +cube-indices+
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                0 3 lwlgl.opengl.gl33:+gl-float-type+ 0 24 (cffi:null-pointer))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 0)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                1 3 lwlgl.opengl.gl33:+gl-float-type+ 0 24 (cffi:make-pointer 12))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 1)
               (lwlgl.opengl.gl33:gl-enable lwlgl.opengl.gl33:+gl-depth-test+)
               (lwlgl.opengl.gl33:gl-depth-func lwlgl.opengl.gl33:+gl-less+)
               (let ((mvp-location
                       (lwlgl.opengl.gl33:gl-get-uniform-location program "uMVP"))
                     (frames 0))
                 (when (minusp mvp-location)
                   (error "The cube shader does not expose uMVP."))
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
                      (let* ((safe-width (max 1 width))
                             (safe-height (max 1 height))
                             (angle (lwlgl.glfw.glfw34:glfw-get-time))
                             (model
                               (lwlgl.math:mat4-mul
                                (lwlgl.math:rotation-y-mat4 angle)
                                (lwlgl.math:rotation-x-mat4 (* angle 0.63d0))))
                             (view (lwlgl.math:translation-mat4 0.0 0.0 -5.0))
                             (projection
                                (lwlgl.math:perspective-mat4
                                (lwlgl.math:degrees->radians 55.0)
                                (/ (float safe-width 1.0) safe-height) 0.1 100.0))
                             (mvp
                               (lwlgl.math:mat4-mul
                                projection (lwlgl.math:mat4-mul view model))))
                        (lwlgl.opengl.gl33:gl-viewport 0 0 width height)
                        (lwlgl.opengl.gl33:gl-clear-color 0.018 0.025 0.045 1.0)
                        (lwlgl.opengl.gl33:gl-clear
                         (logior lwlgl.opengl.gl33:+gl-color-buffer-bit+
                                 lwlgl.opengl.gl33:+gl-depth-buffer-bit+))
                        (lwlgl.opengl.gl33:gl-use-program program)
                        (lwlgl.opengl:set-uniform-mat4 mvp-location mvp)
                        (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
                        (lwlgl.opengl.gl33:gl-draw-elements
                         lwlgl.opengl.gl33:+gl-triangles+ (length +cube-indices+)
                         lwlgl.opengl.gl33:+gl-unsigned-int+ (cffi:null-pointer))))
                    (when (and max-frames (>= (incf frames) max-frames))
                      (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))))
          (when (plusp program)
            (lwlgl.opengl.gl33:gl-delete-program program))
          (lwlgl.opengl:delete-buffer ebo)
          (lwlgl.opengl:delete-buffer vbo)
          (lwlgl.opengl:delete-vertex-array vao))))))
