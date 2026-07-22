(in-package #:lwlgl.core)

(defun runtime-report ()
  "Retorna um plist com dados úteis para diagnóstico e bug reports."
  (list :lwlgl-version *lwlgl-version*
        :lisp-implementation (lisp-implementation-type)
        :lisp-version (lisp-implementation-version)
        :platform (platform)
        :architecture (architecture)
        :configuration
        (list :checks-enabled
              (runtime-configuration-checks-enabled-p *runtime-configuration*)
              :debug-memory
              (runtime-configuration-debug-memory-p *runtime-configuration*)
              :debug-loader
              (runtime-configuration-debug-loader-p *runtime-configuration*))
        :native-search-paths (copy-list *native-search-paths*)
        :native-bundle-roots (copy-list *native-bundle-roots*)
        :modules
        (mapcar (lambda (module)
                  (list :name (native-module-name module)
                        :loaded (native-module-loaded-p module)
                        :libraries (copy-list (native-module-libraries module))))
                (list-native-modules))))

(defun print-runtime-report (&optional (stream *standard-output*))
  (let ((report (runtime-report)))
    (format stream "~&LWLGL ~A~%" (getf report :lwlgl-version))
    (format stream "Lisp: ~A ~A~%" (getf report :lisp-implementation)
            (getf report :lisp-version))
    (format stream "Plataforma: ~A / ~A~%" (getf report :platform)
            (getf report :architecture))
    (format stream "Módulos registrados:~%")
    (dolist (module (getf report :modules))
      (format stream "  ~A: ~:[não carregado~;carregado~]~%"
              (getf module :name) (getf module :loaded)))
    report))


(defmacro with-native-floating-point-environment (() &body body)
  "Executes BODY with host floating-point traps masked where required by native multimedia drivers.
On SBCL this masks INVALID, DIVIDE-BY-ZERO and OVERFLOW for the dynamic extent and restores
the previous floating-point mode afterwards. Other implementations currently execute BODY unchanged."
  #+sbcl
  `(sb-int:with-float-traps-masked (:invalid :divide-by-zero :overflow)
     ,@body)
  #-sbcl
  `(progn ,@body))
