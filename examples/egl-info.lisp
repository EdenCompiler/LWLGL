(in-package #:lwlgl.examples)

(defun egl-info ()
  "Loads EGL, initializes the default display, prints its version, and exits."
  (lwlgl.egl:create)
  (unwind-protect
       (let ((display
               (lwlgl.egl.egl15:egl-get-display (cffi:null-pointer))))
         (when (cffi:null-pointer-p display)
           (error "EGL did not return a default display (error #x~X)."
                  (lwlgl.egl.egl15:egl-get-error)))
         (lwlgl.core:with-memory-stack (stack)
           (let ((major (lwlgl.core:stack-calloc :int 1 :stack stack))
                 (minor (lwlgl.core:stack-calloc :int 1 :stack stack)))
             (unless (plusp
                      (lwlgl.egl.egl15:egl-initialize
                       display (lwlgl.core:native-buffer-pointer major)
                       (lwlgl.core:native-buffer-pointer minor)))
               (error "eglInitialize failed with error #x~X."
                      (lwlgl.egl.egl15:egl-get-error)))
             (unwind-protect
                  (let* ((major-value (lwlgl.core:buffer-ref major 0))
                         (minor-value (lwlgl.core:buffer-ref minor 0))
                         (version-pointer
                           (lwlgl.egl.egl15:egl-query-string
                            display lwlgl.egl.egl15:+egl-version+))
                         (version-string
                           (unless (cffi:null-pointer-p version-pointer)
                             (cffi:foreign-string-to-lisp version-pointer))))
                    (format t "~&EGL ~D.~D~@[ — ~A~]~%"
                            major-value minor-value version-string)
                    (list :major major-value :minor minor-value
                          :version version-string))
               (lwlgl.egl.egl15:egl-terminate display)))))
    (lwlgl.egl:destroy)))
