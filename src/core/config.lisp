(in-package #:lwlgl.core)

(defvar *debug-native-loading* nil)

(defstruct runtime-configuration
  "Process-wide safety and diagnostic controls. Checks default to enabled."
  (checks-enabled-p t :type boolean)
  (debug-memory-p nil :type boolean)
  (debug-loader-p nil :type boolean))

(defparameter *runtime-configuration* (make-runtime-configuration))

(defun configure-runtime (&key
                            (checks-enabled-p nil checks-supplied-p)
                            (debug-memory-p nil memory-supplied-p)
                            (debug-loader-p nil loader-supplied-p))
  "Updates supplied runtime options and returns *RUNTIME-CONFIGURATION*."
  (when checks-supplied-p
    (setf (runtime-configuration-checks-enabled-p *runtime-configuration*)
          (not (null checks-enabled-p))))
  (when memory-supplied-p
    (setf (runtime-configuration-debug-memory-p *runtime-configuration*)
          (not (null debug-memory-p))))
  (when loader-supplied-p
    (setf (runtime-configuration-debug-loader-p *runtime-configuration*)
          (not (null debug-loader-p))
          *debug-native-loading* (not (null debug-loader-p))))
  *runtime-configuration*)
