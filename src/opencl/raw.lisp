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

(defconstant +cl-platform-profile+ platform-profile)
(defconstant +cl-platform-version+ platform-version)
(defconstant +cl-platform-name+ platform-name)
(defconstant +cl-platform-vendor+ platform-vendor)
(defconstant +cl-platform-extensions+ platform-extensions)
(defconstant +cl-device-type-default+ device-type-default)
(defconstant +cl-device-type-cpu+ device-type-cpu)
(defconstant +cl-device-type-gpu+ device-type-gpu)
(defconstant +cl-device-type-accelerator+ device-type-accelerator)
(defconstant +cl-device-type-all+ device-type-all)

(cffi:defcfun ("clGetPlatformIDs" ncl-get-platform-ids) :int
  (num-entries :unsigned-int) (platforms :pointer) (num-platforms :pointer))
(cffi:defcfun ("clGetPlatformInfo" ncl-get-platform-info) :int
  (platform :pointer) (param-name :unsigned-int) (param-value-size :size)
  (param-value :pointer) (param-value-size-ret :pointer))
(cffi:defcfun ("clGetDeviceIDs" ncl-get-device-ids) :int
  (platform :pointer) (device-type-mask :uint64) (num-entries :unsigned-int)
  (devices :pointer) (num-devices :pointer))
(cffi:defcfun ("clGetDeviceInfo" ncl-get-device-info) :int
  (device :pointer) (param-name :unsigned-int) (param-value-size :size)
  (param-value :pointer) (param-value-size-ret :pointer))

(defvar *provider* nil)
(defvar *capabilities* nil)

(defstruct (cl-capabilities (:include lwlgl.core:api-capabilities)
                            (:constructor %make-cl-capabilities)))

(defun create ()
  (lwlgl.core:ensure-native-module :opencl)
  (setf *provider*
        (lwlgl.core:make-function-provider
         :name :opencl
         :resolver (lambda (name)
                     (lwlgl.core:resolve-foreign-symbol name :module :opencl :errorp nil))))
  t)

(defun destroy ()
  (setf *provider* nil *capabilities* nil)
  (lwlgl.core:unload-native-module :opencl)
  nil)

(defun load-opencl () (create))
(defun get-function-provider () (or *provider* (progn (create) *provider*)))

(defun create-capabilities (&key (provider (get-function-provider)))
  (let ((functions (make-hash-table :test #'equal)))
    (dolist (name '("clGetPlatformIDs" "clGetPlatformInfo"
                    "clGetDeviceIDs" "clGetDeviceInfo"))
      (let ((pointer (lwlgl.core:get-function-address provider name)))
        (when pointer (setf (gethash name functions) pointer))))
    (setf *capabilities*
          (%make-cl-capabilities :api :opencl :version '(3 0)
                                 :functions functions))))

(defun get-capabilities ()
  (or *capabilities* (error "No OpenCL capabilities are active.")))
(defun set-capabilities (capabilities) (setf *capabilities* capabilities))
(defmacro with-capabilities ((capabilities) &body body)
  `(let ((*capabilities* ,capabilities)) (locally ,@body)))
(defun cl-function-available-p (name &optional (capabilities (get-capabilities)))
  (not (null (lwlgl.core:capability-function-pointer capabilities name))))

(defmacro %define-checked (checked raw arguments)
  `(defun ,checked ,arguments
     (unless *provider* (create))
     (,raw ,@arguments)))

(%define-checked cl-get-platform-ids ncl-get-platform-ids
  (num-entries platforms num-platforms))
(%define-checked cl-get-platform-info ncl-get-platform-info
  (platform param-name param-value-size param-value param-value-size-ret))
(%define-checked cl-get-device-ids ncl-get-device-ids
  (platform device-type-mask num-entries devices num-devices))
(%define-checked cl-get-device-info ncl-get-device-info
  (device param-name param-value-size param-value param-value-size-ret))

;; Internal compatibility names used by the discovery helpers.
(setf (fdefinition '%cl-get-platform-ids) #'cl-get-platform-ids
      (fdefinition '%cl-get-platform-info) #'cl-get-platform-info
      (fdefinition '%cl-get-device-ids) #'cl-get-device-ids
      (fdefinition '%cl-get-device-info) #'cl-get-device-info)
