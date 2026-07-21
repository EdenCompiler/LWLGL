(defpackage #:lwlgl.opencl
  (:use #:cl)
  (:export
   #:load-opencl #:platforms #:platform-info #:platform-summary
   #:devices #:device-info #:device-info-uint #:device-info-ulong #:device-info-size #:device-info-bool
   #:device-summary #:opencl-report
   #:platform-profile #:platform-version #:platform-name #:platform-vendor #:platform-extensions
   #:device-type-default #:device-type-cpu #:device-type-gpu #:device-type-accelerator #:device-type-all
   #:device-type #:device-vendor-id #:device-max-compute-units #:device-max-work-group-size
   #:device-max-clock-frequency #:device-global-mem-size #:device-local-mem-size #:device-available
   #:device-name #:device-vendor #:driver-version #:device-profile #:device-version #:device-extensions))
