(defpackage #:lwlgl.opencl
  (:use #:cl)
  (:export
   #:create #:destroy #:load-opencl #:get-function-provider
   #:cl-capabilities #:cl-capabilities-p
   #:create-capabilities #:get-capabilities #:set-capabilities #:with-capabilities
   #:cl-function-available-p
   #:cl-get-platform-ids #:ncl-get-platform-ids
   #:cl-get-platform-info #:ncl-get-platform-info
   #:cl-get-device-ids #:ncl-get-device-ids
   #:cl-get-device-info #:ncl-get-device-info
   #:platforms #:platform-info #:platform-summary
   #:devices #:device-info #:device-info-uint #:device-info-ulong #:device-info-size #:device-info-bool
   #:device-summary #:opencl-report
   #:platform-profile #:platform-version #:platform-name #:platform-vendor #:platform-extensions
   #:device-type-default #:device-type-cpu #:device-type-gpu #:device-type-accelerator #:device-type-all
   #:device-type #:device-vendor-id #:device-max-compute-units #:device-max-work-group-size
   #:device-max-clock-frequency #:device-global-mem-size #:device-local-mem-size #:device-available
   #:device-name #:device-vendor #:driver-version #:device-profile #:device-version #:device-extensions
   #:+cl-platform-profile+ #:+cl-platform-version+ #:+cl-platform-name+
   #:+cl-platform-vendor+ #:+cl-platform-extensions+
   #:+cl-device-type-default+ #:+cl-device-type-cpu+ #:+cl-device-type-gpu+
   #:+cl-device-type-accelerator+ #:+cl-device-type-all+))
