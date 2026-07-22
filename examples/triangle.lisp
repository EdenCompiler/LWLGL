(in-package #:lwlgl.examples)

(defparameter +triangle-vertex-shader+
"#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec3 aColor;
out vec3 vColor;
void main() {
  vColor = aColor;
  gl_Position = vec4(aPos, 0.0, 1.0);
}")

(defparameter +triangle-fragment-shader+
"#version 330 core
in vec3 vColor;
out vec4 FragColor;
void main() {
  FragColor = vec4(vColor, 1.0);
}")

(defun triangle (&key max-frames)
  "Renders a GL 3.3 triangle. MAX-FRAMES enables unattended smoke tests."
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
    (lwlgl.glfw.glfw34:glfw-with-window (window 900 600 "LWLGL — Triangle")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.glfw.glfw34:glfw-swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((vao (lwlgl.opengl:make-vertex-array))
            (vbo (lwlgl.opengl:make-buffer))
            (program (lwlgl.opengl:make-program +triangle-vertex-shader+ +triangle-fragment-shader+)))
        (unwind-protect
             (progn
               (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
               (lwlgl.opengl.gl33:gl-bind-buffer lwlgl.opengl.gl33:+gl-array-buffer+ vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl.gl33:+gl-array-buffer+
                #(-0.60 -0.50  1.0 0.2 0.2
                   0.60 -0.50  0.2 1.0 0.3
                   0.00  0.62  0.2 0.4 1.0)
                lwlgl.opengl.gl33:+gl-static-draw+)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                0 2 lwlgl.opengl.gl33:+gl-float-type+ 0 (* 5 4) (cffi:null-pointer))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 0)
               (lwlgl.opengl.gl33:gl-vertex-attrib-pointer
                1 3 lwlgl.opengl.gl33:+gl-float-type+ 0 (* 5 4)
                (cffi:make-pointer (* 2 4)))
               (lwlgl.opengl.gl33:gl-enable-vertex-attrib-array 1)
               (let ((frames 0))
                 (lwlgl.glfw.glfw34:glfw-run-loop
                  window
                  (lambda (window)
                    (multiple-value-bind (width height)
                        (lwlgl.glfw.glfw34:glfw-framebuffer-size window)
                      (lwlgl.opengl.gl33:gl-viewport 0 0 width height))
                    (lwlgl.opengl.gl33:gl-clear-color 0.03 0.03 0.04 1.0)
                    (lwlgl.opengl.gl33:gl-clear
                     lwlgl.opengl.gl33:+gl-color-buffer-bit+)
                    (lwlgl.opengl.gl33:gl-use-program program)
                    (lwlgl.opengl.gl33:gl-bind-vertex-array vao)
                    (lwlgl.opengl.gl33:gl-draw-arrays
                     lwlgl.opengl.gl33:+gl-triangles+ 0 3)
                    (when (and max-frames (>= (incf frames) max-frames))
                      (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))))
          (lwlgl.opengl.gl33:gl-delete-program program)
          (lwlgl.opengl:delete-buffer vbo)
          (lwlgl.opengl:delete-vertex-array vao))))))
