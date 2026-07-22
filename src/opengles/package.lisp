(defpackage #:lwlgl.opengles
  (:use #:cl)
  (:export
   #:gles-capabilities #:gles-capabilities-p #:create-capabilities
   #:get-capabilities #:set-capabilities #:with-capabilities
   #:gl-function-available-p
   #:ngl-clear-color #:gl-clear-color #:ngl-clear #:gl-clear
   #:ngl-viewport #:gl-viewport #:ngl-get-error #:gl-get-error
   #:+gl-color-buffer-bit+ #:+gl-depth-buffer-bit+ #:+gl-stencil-buffer-bit+))

(defpackage #:lwlgl.opengles.gles20 (:use #:cl))
(defpackage #:lwlgl.opengles.gles30 (:use #:cl #:lwlgl.opengles.gles20))
(defpackage #:lwlgl.opengles.gles31 (:use #:cl #:lwlgl.opengles.gles30))
(defpackage #:lwlgl.opengles.gles32 (:use #:cl #:lwlgl.opengles.gles31))
