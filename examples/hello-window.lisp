(in-package #:lwlgl.examples)

(defun hello-window (&key max-frames)
  "Opens a GL 3.3 window. MAX-FRAMES makes the example suitable for smoke tests."
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
    (lwlgl.glfw.glfw34:glfw-with-window (window 800 600 "LWLGL — Hello")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.glfw.glfw34:glfw-swap-interval 1)
      (lwlgl.opengl:load-opengl :error-on-missing nil)
      (lwlgl.glfw.glfw34:glfw-set-key-handler
       window
       (lambda (window key scancode action mods)
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
           (lwlgl.opengl.gl33:gl-clear-color 0.08 0.10 0.14 1.0)
           (lwlgl.opengl.gl33:gl-clear
            lwlgl.opengl.gl33:+gl-color-buffer-bit+)
           (when (and max-frames (>= (incf frames) max-frames))
             (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))))))))
