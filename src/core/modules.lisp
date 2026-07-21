(in-package #:lwlgl.core)

(defparameter *debug-native-loading* nil)
(defparameter *native-search-paths* '())
(defvar *native-modules* (make-hash-table :test #'eq))

(defstruct native-module
  name
  libraries
  handle
  (loaded-p nil))

(defun register-native-module (name libraries)
  "Registra NAME com uma lista ordenada de nomes candidatos."
  (setf (gethash name *native-modules*)
        (make-native-module :name name :libraries libraries)))

(defun find-native-module (name)
  (gethash name *native-modules*))

(defun list-native-modules ()
  (sort (loop for value being the hash-values of *native-modules* collect value)
        #'string< :key (lambda (module) (string (native-module-name module)))))

(defun add-native-search-path (path)
  "Adiciona PATH às rotas usadas pelo carregador CFFI."
  (let ((absolute (namestring (uiop:ensure-directory-pathname path))))
    (pushnew absolute *native-search-paths* :test #'string=)
    (pushnew absolute cffi:*foreign-library-directories* :test #'string=)
    absolute))

(defun %try-load-library (candidate)
  (when *debug-native-loading*
    (format *trace-output* "~&[LWLGL] tentando carregar ~A~%" candidate))
  (cffi:load-foreign-library candidate))

(defun ensure-native-module (name)
  "Carrega sob demanda o primeiro nome de biblioteca que funcionar para NAME."
  (let ((module (or (find-native-module name)
                    (error 'native-library-error :module name
                           :cause "módulo não registrado"))))
    (if (native-module-loaded-p module)
        module
        (let ((last-error nil))
          (dolist (candidate (native-module-libraries module))
            (handler-case
                (let ((handle (%try-load-library candidate)))
                  (setf (native-module-handle module) handle
                        (native-module-loaded-p module) t)
                  (return-from ensure-native-module module))
              (error (condition)
                (setf last-error condition))))
          (error 'native-library-error :module name
                 :cause (or last-error "nenhum nome de biblioteca disponível"))))))

(defun unload-native-module (name)
  "Descarrega um módulo carregado. Use somente quando não existirem ponteiros ativos."
  (let ((module (find-native-module name)))
    (when (and module (native-module-loaded-p module))
      (ignore-errors (cffi:close-foreign-library (native-module-handle module)))
      (setf (native-module-handle module) nil
            (native-module-loaded-p module) nil))
    module))

(defmacro with-native-module ((name) &body body)
  `(progn
     (ensure-native-module ,name)
     ,@body))

(defun resolve-foreign-symbol (name &key module (errorp t))
  "Resolve NAME optionally after ensuring MODULE, across CFFI versions."
  (when module (ensure-native-module module))
  (handler-case
      (let ((pointer (cffi:foreign-symbol-pointer name)))
        (cond
          ((and pointer (not (cffi:null-pointer-p pointer))) pointer)
          (errorp (error 'missing-native-symbol :name name))
          (t nil)))
    (error ()
      (if errorp
          (error 'missing-native-symbol :name name)
          nil))))

(defun foreign-symbol-available-p (name &key module)
  (not (null (resolve-foreign-symbol name :module module :errorp nil))))
