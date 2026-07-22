(in-package #:lwlgl.vulkan)

(lwlgl.core:register-native-module
 :vulkan
 (lwlgl.core:platform-library-names
  :windows '("vulkan-1.dll")
  :macos '("libvulkan.1.dylib" "libvulkan.dylib" "libMoltenVK.dylib")
  :linux '("libvulkan.so.1" "libvulkan.so")))

(defconstant +vk-success+ 0)
(defconstant +vk-incomplete+ 5)
(defconstant +vk-max-extension-name-size+ 256)
(defconstant +vk-max-description-size+ 256)

(cffi:defcstruct vk-extension-properties
  (extension-name :char :count 256)
  (spec-version :unsigned-int))

(cffi:defcstruct vk-layer-properties
  (layer-name :char :count 256)
  (spec-version :unsigned-int)
  (implementation-version :unsigned-int)
  (description :char :count 256))

(defvar *vk-get-instance-proc-addr* nil)
(defvar *provider* nil)

(defstruct (vk-capabilities-instance (:include lwlgl.core:api-capabilities)
                                     (:constructor %make-vk-capabilities-instance)))
(defstruct (vk-capabilities-device (:include lwlgl.core:api-capabilities)
                                   (:constructor %make-vk-capabilities-device)))

(defun load-vulkan ()
  (lwlgl.core:ensure-native-module :vulkan)
  (setf *vk-get-instance-proc-addr*
        (lwlgl.core:resolve-foreign-symbol "vkGetInstanceProcAddr" :module :vulkan)
        *provider*
        (lwlgl.core:make-function-provider
         :name :vulkan
         :resolver (lambda (name)
                     (nvk-get-instance-proc-addr (cffi:null-pointer) name))))
  t)

(defun create () (load-vulkan))

(defun destroy ()
  (setf *provider* nil *vk-get-instance-proc-addr* nil)
  (lwlgl.core:unload-native-module :vulkan)
  nil)

(defun get-function-provider () (or *provider* (progn (create) *provider*)))

(defun vulkan-supported-p ()
  (handler-case (progn (load-vulkan) t) (error () nil)))

(defun nvk-get-instance-proc-addr (instance name)
  (unless *vk-get-instance-proc-addr* (load-vulkan))
  (cffi:foreign-funcall-pointer *vk-get-instance-proc-addr* ()
                                :pointer instance :string name :pointer))

(defun vk-get-instance-proc-addr (instance name)
  (nvk-get-instance-proc-addr instance name))

(defun get-instance-proc-address (instance name)
  (vk-get-instance-proc-addr instance name))

(defun %global-function (name)
  (let ((pointer (get-instance-proc-address (cffi:null-pointer) name)))
    (when (or (null pointer) (cffi:null-pointer-p pointer))
      (error "Vulkan loader does not expose ~A." name))
    pointer))

(defun nvk-enumerate-instance-version (version)
  (cffi:foreign-funcall-pointer (%global-function "vkEnumerateInstanceVersion") ()
                                :pointer version :int))
(defun vk-enumerate-instance-version (version)
  (nvk-enumerate-instance-version version))

(defun nvk-enumerate-instance-extension-properties (layer-name count properties)
  (cffi:foreign-funcall-pointer
   (%global-function "vkEnumerateInstanceExtensionProperties") ()
   :pointer layer-name :pointer count :pointer properties :int))
(defun vk-enumerate-instance-extension-properties (layer-name count properties)
  (nvk-enumerate-instance-extension-properties layer-name count properties))

(defun nvk-enumerate-instance-layer-properties (count properties)
  (cffi:foreign-funcall-pointer
   (%global-function "vkEnumerateInstanceLayerProperties") ()
   :pointer count :pointer properties :int))
(defun vk-enumerate-instance-layer-properties (count properties)
  (nvk-enumerate-instance-layer-properties count properties))

(defun create-instance-capabilities (&key instance)
  (unless *vk-get-instance-proc-addr* (load-vulkan))
  (let ((functions (make-hash-table :test #'equal)))
    (dolist (name '("vkGetInstanceProcAddr" "vkEnumerateInstanceVersion"
                    "vkEnumerateInstanceExtensionProperties"
                    "vkEnumerateInstanceLayerProperties"))
      (let ((pointer (if (string= name "vkGetInstanceProcAddr")
                         *vk-get-instance-proc-addr*
                         (vk-get-instance-proc-addr
                          (or instance (cffi:null-pointer)) name))))
        (when (and pointer (not (cffi:null-pointer-p pointer)))
          (setf (gethash name functions) pointer))))
    (%make-vk-capabilities-instance :api :vulkan :version '(1 4)
                                    :functions functions)))

(defun create-device-capabilities (device get-device-proc-address)
  (declare (ignore device))
  (%make-vk-capabilities-device
   :api :vulkan :version '(1 4)
   :functions (make-hash-table :test #'equal)
   :features (let ((features (make-hash-table :test #'equal)))
               (setf (gethash :get-device-proc-address features)
                     get-device-proc-address)
               features)))

(defun make-vulkan-version (major minor patch)
  (logior (ash major 22) (ash minor 12) patch))

(defun vulkan-instance-version ()
  "Returns the maximum Vulkan API version reported by the loader; assumes 1.0 if unavailable."
  (unless *vk-get-instance-proc-addr* (load-vulkan))
  (let ((function (get-instance-proc-address (cffi:null-pointer) "vkEnumerateInstanceVersion")))
    (if (or (null function) (cffi:null-pointer-p function))
        (make-vulkan-version 1 0 0)
        (cffi:with-foreign-object (version :unsigned-int)
          (let ((result (vk-enumerate-instance-version version)))
            (unless (= result +vk-success+)
              (error "vkEnumerateInstanceVersion failed: ~A" result))
            (cffi:mem-ref version :unsigned-int))))))

(defun decode-vulkan-version (version)
  "Returns major, minor and patch as multiple values."
  (values (ldb (byte 7 22) version)
          (ldb (byte 10 12) version)
          (ldb (byte 12 0) version)))

(defun vulkan-instance-extensions (&optional layer-name)
  "Enumerates instance extensions as plists (:NAME string :SPEC-VERSION integer)."
  (let ((function (%global-function "vkEnumerateInstanceExtensionProperties")))
    (labels ((call (layer count properties)
               (cffi:foreign-funcall-pointer function ()
                                             :pointer layer :pointer count :pointer properties :int)))
      (cffi:with-foreign-object (count :unsigned-int)
        (let ((layer-pointer (if layer-name
                                 (cffi:foreign-string-alloc layer-name)
                                 (cffi:null-pointer))))
          (unwind-protect
               (progn
                 (let ((result (call layer-pointer count (cffi:null-pointer))))
                   (unless (member result (list +vk-success+ +vk-incomplete+))
                     (error "vkEnumerateInstanceExtensionProperties failed: ~A" result)))
                 (let ((n (cffi:mem-ref count :unsigned-int)))
                   (if (zerop n) '()
                       (cffi:with-foreign-object (items '(:struct vk-extension-properties) n)
                         (let ((result (call layer-pointer count items)))
                           (unless (member result (list +vk-success+ +vk-incomplete+))
                             (error "vkEnumerateInstanceExtensionProperties failed: ~A" result)))
                         (loop for i below (cffi:mem-ref count :unsigned-int)
                               for item = (cffi:mem-aptr items '(:struct vk-extension-properties) i)
                               collect (list :name (cffi:foreign-string-to-lisp
                                                    (cffi:foreign-slot-pointer item '(:struct vk-extension-properties) 'extension-name))
                                             :spec-version (cffi:foreign-slot-value item '(:struct vk-extension-properties) 'spec-version)))))))
            (unless (cffi:null-pointer-p layer-pointer)
              (cffi:foreign-string-free layer-pointer))))))))

(defun vulkan-instance-layers ()
  "Enumerates instance layers as descriptive plists."
  (let ((function (%global-function "vkEnumerateInstanceLayerProperties")))
    (labels ((call (count properties)
               (cffi:foreign-funcall-pointer function () :pointer count :pointer properties :int)))
      (cffi:with-foreign-object (count :unsigned-int)
        (let ((result (call count (cffi:null-pointer))))
          (unless (member result (list +vk-success+ +vk-incomplete+))
            (error "vkEnumerateInstanceLayerProperties failed: ~A" result)))
        (let ((n (cffi:mem-ref count :unsigned-int)))
          (if (zerop n) '()
              (cffi:with-foreign-object (items '(:struct vk-layer-properties) n)
                (let ((result (call count items)))
                  (unless (member result (list +vk-success+ +vk-incomplete+))
                    (error "vkEnumerateInstanceLayerProperties failed: ~A" result)))
                (loop for i below (cffi:mem-ref count :unsigned-int)
                      for item = (cffi:mem-aptr items '(:struct vk-layer-properties) i)
                      collect
                      (list :name (cffi:foreign-string-to-lisp
                                   (cffi:foreign-slot-pointer item '(:struct vk-layer-properties) 'layer-name))
                            :spec-version (cffi:foreign-slot-value item '(:struct vk-layer-properties) 'spec-version)
                            :implementation-version (cffi:foreign-slot-value item '(:struct vk-layer-properties) 'implementation-version)
                            :description (cffi:foreign-string-to-lisp
                                          (cffi:foreign-slot-pointer item '(:struct vk-layer-properties) 'description)))))))))))

(defun vulkan-loader-info ()
  (let ((version (vulkan-instance-version)))
    (multiple-value-bind (major minor patch) (decode-vulkan-version version)
      (list :api-version version
            :major major :minor minor :patch patch
            :extensions (vulkan-instance-extensions)
            :layers (vulkan-instance-layers)))))
