(in-package #:lwlgl.examples)

(defun input-demo (&key max-frames)
  "Demonstrates stateful input and timing. MAX-FRAMES supports smoke tests."
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
    (lwlgl.glfw.glfw34:glfw-with-window (window 800 500 "LWLGL — Input Demo")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.glfw.glfw34:glfw-swap-interval 1)
      (lwlgl.opengl:load-opengl)
      (let ((input (lwlgl.input:make-input-state window))
            (clock (lwlgl.util:make-frame-clock))
            (x 0.0d0) (y 0.0d0) (frames 0))
        (unwind-protect
             (loop until (lwlgl.glfw.glfw34:glfw-window-should-close-p window)
                   do (lwlgl.input:begin-input-frame input)
                      (lwlgl.glfw.glfw34:glfw-poll-events)
                      (multiple-value-bind (dt elapsed fps) (lwlgl.util:tick-frame-clock clock)
                        (declare (ignore elapsed))
                        (let ((speed (* 0.8d0 dt)))
                          (when (lwlgl.input:key-down-p
                                 input lwlgl.glfw.glfw34:+glfw-key-a+) (decf x speed))
                          (when (lwlgl.input:key-down-p
                                 input lwlgl.glfw.glfw34:+glfw-key-d+) (incf x speed))
                          (when (lwlgl.input:key-down-p
                                 input lwlgl.glfw.glfw34:+glfw-key-w+) (incf y speed))
                          (when (lwlgl.input:key-down-p
                                 input lwlgl.glfw.glfw34:+glfw-key-s+) (decf y speed)))
                        (when (lwlgl.input:key-pressed-p
                               input lwlgl.glfw.glfw34:+glfw-key-escape+)
                          (lwlgl.glfw.glfw34:glfw-set-window-should-close window t))
                        (when (plusp fps)
                          (lwlgl.glfw.glfw34:glfw-set-window-title
                           window (format nil "LWLGL — Input Demo | WASD (~,2F, ~,2F) | ~,0F FPS" x y fps))))
                      (multiple-value-bind (width height)
                          (lwlgl.glfw.glfw34:glfw-framebuffer-size window)
                        (lwlgl.opengl.gl33:gl-viewport 0 0 width height))
                      (lwlgl.opengl.gl33:gl-clear-color
                       (coerce (lwlgl.util:clamp (+ 0.12d0 (* x 0.12d0)) 0.02d0 0.35d0) 'single-float)
                       (coerce (lwlgl.util:clamp (+ 0.14d0 (* y 0.12d0)) 0.02d0 0.35d0) 'single-float)
                       0.20 1.0)
                      (lwlgl.opengl.gl33:gl-clear
                       lwlgl.opengl.gl33:+gl-color-buffer-bit+)
                      (lwlgl.glfw.glfw34:glfw-swap-buffers window)
                      (when (and max-frames (>= (incf frames) max-frames))
                        (lwlgl.glfw.glfw34:glfw-set-window-should-close window t)))
          (lwlgl.input:detach-input-state input))))))
