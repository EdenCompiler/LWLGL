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

(defun triangle ()
  "Renderiza um triângulo colorido usando OpenGL 3.3 core."
  (lwlgl.glfw:with-glfw ()
    (lwlgl.glfw:default-window-hints)
    (lwlgl.glfw:window-hint lwlgl.glfw:context-version-major 3)
    (lwlgl.glfw:window-hint lwlgl.glfw:context-version-minor 3)
    (lwlgl.glfw:window-hint lwlgl.glfw:opengl-profile lwlgl.glfw:opengl-core-profile)
    #+darwin (lwlgl.glfw:window-hint lwlgl.glfw:opengl-forward-compat lwlgl.glfw:true)
    (lwlgl.glfw:with-window (window 900 600 "LWLGL — Triangle")
      (lwlgl.glfw:make-context-current window)
      (lwlgl.glfw:swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((vao (lwlgl.opengl:make-vertex-array))
            (vbo (lwlgl.opengl:make-buffer))
            (program (lwlgl.opengl:make-program +triangle-vertex-shader+ +triangle-fragment-shader+)))
        (unwind-protect
             (progn
               (lwlgl.opengl:gl-bind-vertex-array vao)
               (lwlgl.opengl:gl-bind-buffer lwlgl.opengl:array-buffer vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl:array-buffer
                #(-0.60 -0.50  1.0 0.2 0.2
                   0.60 -0.50  0.2 1.0 0.3
                   0.00  0.62  0.2 0.4 1.0)
                lwlgl.opengl:static-draw)
               (lwlgl.opengl:gl-vertex-attrib-pointer 0 2 lwlgl.opengl:float-type 0 (* 5 4) (cffi:null-pointer))
               (lwlgl.opengl:gl-enable-vertex-attrib-array 0)
               (lwlgl.opengl:gl-vertex-attrib-pointer 1 3 lwlgl.opengl:float-type 0 (* 5 4) (cffi:make-pointer (* 2 4)))
               (lwlgl.opengl:gl-enable-vertex-attrib-array 1)
               (lwlgl.glfw:run-loop
                window
                (lambda (window)
                  (multiple-value-bind (width height) (lwlgl.glfw:framebuffer-size window)
                    (lwlgl.opengl:gl-viewport 0 0 width height))
                  (lwlgl.opengl:gl-clear-color 0.03 0.03 0.04 1.0)
                  (lwlgl.opengl:gl-clear lwlgl.opengl:color-buffer-bit)
                  (lwlgl.opengl:gl-use-program program)
                  (lwlgl.opengl:gl-bind-vertex-array vao)
                  (lwlgl.opengl:gl-draw-arrays lwlgl.opengl:triangles 0 3))))
          (lwlgl.opengl:gl-delete-program program)
          (lwlgl.opengl:delete-buffer vbo)
          (lwlgl.opengl:delete-vertex-array vao))))))
