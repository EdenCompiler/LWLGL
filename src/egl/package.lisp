(defpackage #:lwlgl.egl
  (:use #:cl)
  (:export
   #:create #:destroy #:egl-loaded-p #:get-function-provider
   #:negl-get-display #:egl-get-display #:negl-initialize #:egl-initialize
   #:negl-terminate #:egl-terminate #:negl-get-proc-address #:egl-get-proc-address
   #:negl-get-error #:egl-get-error #:negl-query-string #:egl-query-string
   #:+egl-false+ #:+egl-true+ #:+egl-none+ #:+egl-default-display+
   #:+egl-opengl-es-api+ #:+egl-opengl-api+ #:+egl-version+ #:+egl-extensions+))

(defpackage #:lwlgl.egl.egl15
  (:use #:cl #:lwlgl.egl))
