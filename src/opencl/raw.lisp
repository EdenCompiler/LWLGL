(in-package #:lwlgl.opencl)

(lwlgl.core:register-native-module
 :opencl
 (lwlgl.core:platform-library-names
  :windows '("OpenCL.dll")
  :macos '("/System/Library/Frameworks/OpenCL.framework/OpenCL")
  :linux '("libOpenCL.so.1" "libOpenCL.so")))

(defconstant platform-profile #x0900)
(defconstant platform-version #x0901)
(defconstant platform-name #x0902)
(defconstant platform-vendor #x0903)
(defconstant platform-extensions #x0904)
(defconstant device-type-default 1)
(defconstant device-type-cpu 2)
(defconstant device-type-gpu 4)
(defconstant device-type-accelerator 8)
(defconstant device-type-all #xFFFFFFFF)
(defconstant device-type #x1000)
(defconstant device-vendor-id #x1001)
(defconstant device-max-compute-units #x1002)
(defconstant device-max-work-group-size #x1004)
(defconstant device-max-clock-frequency #x100C)
(defconstant device-global-mem-size #x101F)
(defconstant device-local-mem-size #x1023)
(defconstant device-available #x1027)
(defconstant device-name #x102B)
(defconstant device-vendor #x102C)
(defconstant driver-version #x102D)
(defconstant device-profile #x102E)
(defconstant device-version #x102F)
(defconstant device-extensions #x1030)

(cffi:defcfun ("clGetPlatformIDs" %cl-get-platform-ids) :int
  (num-entries :unsigned-int) (platforms :pointer) (num-platforms :pointer))
(cffi:defcfun ("clGetPlatformInfo" %cl-get-platform-info) :int
  (platform :pointer) (param-name :unsigned-int) (param-value-size :size)
  (param-value :pointer) (param-value-size-ret :pointer))
(cffi:defcfun ("clGetDeviceIDs" %cl-get-device-ids) :int
  (platform :pointer) (device-type-mask :uint64) (num-entries :unsigned-int)
  (devices :pointer) (num-devices :pointer))
(cffi:defcfun ("clGetDeviceInfo" %cl-get-device-info) :int
  (device :pointer) (param-name :unsigned-int) (param-value-size :size)
  (param-value :pointer) (param-value-size-ret :pointer))

(defun load-opencl () (lwlgl.core:ensure-native-module :opencl) t)
