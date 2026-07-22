(in-package #:lwlgl.examples)

(defun opengl-info ()
  "Creates a hidden GL 3.3 context, prints its capabilities, and exits."
  (lwlgl.glfw.glfw34:glfw-with-glfw ()
    (lwlgl.glfw.glfw34:glfw-default-window-hints)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-visible+ lwlgl.glfw.glfw34:+glfw-false+)
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
    (lwlgl.glfw.glfw34:glfw-with-window (window 64 64 "LWLGL capability probe")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (multiple-value-bind (complete missing capabilities)
          (lwlgl.opengl:load-opengl :error-on-missing nil)
        (declare (ignore capabilities))
        (let ((info (lwlgl.opengl:gl-info)))
          (format t "~&OpenGL ~A — ~A~%"
                  (getf info :version) (getf info :renderer))
          (format t "Resolved ~D commands; complete=~S; missing=~S~%"
                  (length (lwlgl.opengl:gl-capabilities)) complete missing)
          info)))))
