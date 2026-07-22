(in-package #:lwlgl.core)

(defstruct function-provider
  name
  resolver)

(defun get-function-address (provider native-name &key required)
  "Resolves NATIVE-NAME through PROVIDER, optionally requiring a non-null pointer."
  (let ((pointer (funcall (function-provider-resolver provider) native-name)))
    (if (or (null pointer) (cffi:null-pointer-p pointer))
        (when required (error 'missing-native-symbol :name native-name))
        pointer)))

(defstruct api-capabilities
  api
  version
  (functions (make-hash-table :test #'equal) :type hash-table)
  (features (make-hash-table :test #'equal) :type hash-table))

(defun capability-function-pointer (capabilities native-name)
  (gethash native-name (api-capabilities-functions capabilities)))

(defun capability-supported-p (capabilities feature)
  (not (null (gethash feature (api-capabilities-features capabilities)))))

(defun require-capability-function (capabilities native-name)
  (or (capability-function-pointer capabilities native-name)
      (error 'missing-native-symbol :name native-name)))

(defstruct dispatchable-handle
  pointer
  capabilities
  parent)

(defstruct (callback-resource (:constructor %make-callback-resource))
  pointer
  function
  releaser
  (active-p t :type boolean))

(defun make-callback-resource (pointer function &key releaser)
  "Creates an explicitly owned callback wrapper around a native trampoline pointer."
  (%make-callback-resource :pointer pointer :function function :releaser releaser))

(defun free-callback (callback)
  "Releases CALLBACK once. The optional releaser receives its native pointer."
  (when (and callback (callback-resource-active-p callback))
    (when (callback-resource-releaser callback)
      (funcall (callback-resource-releaser callback)
               (callback-resource-pointer callback)))
    (setf (callback-resource-active-p callback) nil
          (callback-resource-pointer callback) (cffi:null-pointer)
          (callback-resource-function callback) nil))
  callback)

(defmacro with-callback ((var callback-form) &body body)
  `(let ((,var ,callback-form))
     (unwind-protect (locally ,@body)
       (free-callback ,var))))
