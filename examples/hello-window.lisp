(in-package #:lwlgl.examples)

(defun hello-window ()
  "Abre uma janela vazia até Esc ou fechamento pelo usuário."
  (lwlgl.glfw:with-glfw ()
    (lwlgl.glfw:default-window-hints)
    (lwlgl.glfw:window-hint lwlgl.glfw:context-version-major 3)
    (lwlgl.glfw:window-hint lwlgl.glfw:context-version-minor 3)
    (lwlgl.glfw:window-hint lwlgl.glfw:opengl-profile lwlgl.glfw:opengl-core-profile)
    #+darwin (lwlgl.glfw:window-hint lwlgl.glfw:opengl-forward-compat lwlgl.glfw:true)
    (lwlgl.glfw:with-window (window 800 600 "LWLGL — Hello")
      (lwlgl.glfw:make-context-current window)
      (lwlgl.glfw:swap-interval 1)
      (lwlgl.opengl:load-opengl :error-on-missing nil)
      (lwlgl.glfw:set-key-handler
       window
       (lambda (window key scancode action mods)
         (declare (ignore scancode mods))
         (when (and (= key lwlgl.glfw:key-escape) (= action lwlgl.glfw:press))
           (lwlgl.glfw:set-window-should-close window t))))
      (lwlgl.glfw:run-loop
       window
       (lambda (window)
         (multiple-value-bind (width height) (lwlgl.glfw:framebuffer-size window)
           (lwlgl.opengl:gl-viewport 0 0 width height))
         (lwlgl.opengl:gl-clear-color 0.08 0.10 0.14 1.0)
         (lwlgl.opengl:gl-clear lwlgl.opengl:color-buffer-bit))))))
