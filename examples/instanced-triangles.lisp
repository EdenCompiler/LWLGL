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

(defun instanced-triangles ()
  "Draws several triangles in one instanced draw call (OpenGL 3.3)."
  (lwlgl.glfw:with-glfw ()
    (lwlgl.glfw:default-window-hints)
    (lwlgl.glfw:window-hint lwlgl.glfw:context-version-major 3)
    (lwlgl.glfw:window-hint lwlgl.glfw:context-version-minor 3)
    (lwlgl.glfw:window-hint lwlgl.glfw:opengl-profile lwlgl.glfw:opengl-core-profile)
    #+darwin (lwlgl.glfw:window-hint lwlgl.glfw:opengl-forward-compat lwlgl.glfw:true)
    (lwlgl.glfw:with-window (window 900 600 "LWLGL — Instanced Rendering")
      (lwlgl.glfw:make-context-current window)
      (lwlgl.glfw:swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((vao (lwlgl.opengl:make-vertex-array))
            (vertex-vbo (lwlgl.opengl:make-buffer))
            (instance-vbo (lwlgl.opengl:make-buffer))
            (program (lwlgl.opengl:make-program +instanced-vertex-shader+ +instanced-fragment-shader+)))
        (unwind-protect
             (progn
               (lwlgl.opengl:gl-bind-vertex-array vao)
               (lwlgl.opengl:gl-bind-buffer lwlgl.opengl:array-buffer vertex-vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl:array-buffer
                #(-0.55 -0.45  1.0 0.25 0.20
                   0.55 -0.45  0.20 1.0 0.35
                   0.00  0.55  0.25 0.45 1.0)
                lwlgl.opengl:static-draw)
               (lwlgl.opengl:gl-vertex-attrib-pointer 0 2 lwlgl.opengl:float-type 0 20 (cffi:null-pointer))
               (lwlgl.opengl:gl-enable-vertex-attrib-array 0)
               (lwlgl.opengl:gl-vertex-attrib-pointer 1 3 lwlgl.opengl:float-type 0 20 (cffi:make-pointer 8))
               (lwlgl.opengl:gl-enable-vertex-attrib-array 1)

               (lwlgl.opengl:gl-bind-buffer lwlgl.opengl:array-buffer instance-vbo)
               (lwlgl.opengl:upload-floats
                lwlgl.opengl:array-buffer
                #(-0.62 0.45   0.0 0.45   0.62 0.45
                  -0.62 -0.45  0.0 -0.45  0.62 -0.45)
                lwlgl.opengl:static-draw)
               (lwlgl.opengl:gl-vertex-attrib-pointer 2 2 lwlgl.opengl:float-type 0 8 (cffi:null-pointer))
               (lwlgl.opengl:gl-enable-vertex-attrib-array 2)
               (lwlgl.opengl:gl-vertex-attrib-divisor 2 1)

               (lwlgl.glfw:set-key-handler
                window (lambda (window key scancode action mods)
                         (declare (ignore scancode mods))
                         (when (and (= key lwlgl.glfw:key-escape) (= action lwlgl.glfw:press))
                           (lwlgl.glfw:set-window-should-close window t))))
               (lwlgl.glfw:run-loop
                window
                (lambda (window)
                  (multiple-value-bind (width height) (lwlgl.glfw:framebuffer-size window)
                    (lwlgl.opengl:gl-viewport 0 0 width height))
                  (lwlgl.opengl:gl-clear-color 0.025 0.03 0.045 1.0)
                  (lwlgl.opengl:gl-clear lwlgl.opengl:color-buffer-bit)
                  (lwlgl.opengl:gl-use-program program)
                  (lwlgl.opengl:gl-bind-vertex-array vao)
                  (lwlgl.opengl:gl-draw-arrays-instanced lwlgl.opengl:triangles 0 3 6))))
          (lwlgl.opengl:gl-delete-program program)
          (lwlgl.opengl:delete-buffer instance-vbo)
          (lwlgl.opengl:delete-buffer vertex-vbo)
          (lwlgl.opengl:delete-vertex-array vao))))))
