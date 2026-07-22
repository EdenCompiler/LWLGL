(in-package #:lwlgl.examples)

(defun offscreen-framebuffer (&key (width 64) (height 64))
  "Clears an offscreen RGBA framebuffer and reads its center pixel back to Lisp."
  (check-type width (integer 1 *))
  (check-type height (integer 1 *))
  (lwlgl.glfw.glfw34:glfw-with-glfw ()
    (lwlgl.glfw.glfw34:glfw-default-window-hints)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-visible+ lwlgl.glfw.glfw34:+glfw-false+)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-context-version-major+ 3)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-context-version-minor+ 3)
    (lwlgl.glfw.glfw34:glfw-with-window (window 32 32 "LWLGL offscreen framebuffer")
      (lwlgl.glfw.glfw34:glfw-make-context-current window)
      (lwlgl.opengl:load-opengl)
      (let ((framebuffer 0) (texture 0) (renderbuffer 0))
        (unwind-protect
             (progn
               (multiple-value-setq (framebuffer texture renderbuffer)
                 (lwlgl.opengl:create-color-framebuffer
                  width height :with-depth-stencil nil))
               (lwlgl.opengl.gl33:gl-bind-framebuffer
                lwlgl.opengl.gl33:+gl-framebuffer+ framebuffer)
               (lwlgl.opengl.gl33:gl-viewport 0 0 width height)
               (lwlgl.opengl.gl33:gl-clear-color 0.20 0.40 0.80 1.0)
               (lwlgl.opengl.gl33:gl-clear
                lwlgl.opengl.gl33:+gl-color-buffer-bit+)
               (lwlgl.opengl.gl33:gl-finish)
               (let* ((pixel
                        (lwlgl.opengl:read-pixels-rgba
                         (floor width 2) (floor height 2) 1 1))
                      (rgba (coerce pixel 'list)))
                 (format t "~&Offscreen ~Dx~D center pixel: ~S~%" width height rgba)
                 (list :width width :height height :center-rgba rgba)))
          (lwlgl.opengl.gl33:gl-bind-framebuffer
           lwlgl.opengl.gl33:+gl-framebuffer+ 0)
          (when (plusp renderbuffer)
            (lwlgl.opengl:delete-renderbuffer renderbuffer))
          (when (plusp texture) (lwlgl.opengl:delete-texture texture))
          (when (plusp framebuffer)
            (lwlgl.opengl:delete-framebuffer framebuffer)))))))
