(in-package #:lwlgl.egl)

(lwlgl.core:register-native-module
 :egl
 (lwlgl.core:platform-library-names
  :windows '("libEGL.dll" "EGL.dll")
  :macos '("libEGL.dylib")
  :linux '("libEGL.so.1" "libEGL.so")))

(defconstant +egl-false+ 0)
(defconstant +egl-true+ 1)
(defconstant +egl-none+ #x3038)
(defconstant +egl-default-display+ 0)
(defconstant +egl-opengl-es-api+ #x30A0)
(defconstant +egl-opengl-api+ #x30A2)
(defconstant +egl-version+ #x3054)
(defconstant +egl-extensions+ #x3055)

(defvar *provider* nil)

(defun create (&key library-name)
  (when library-name
    (lwlgl.core:add-native-search-path
     (uiop:pathname-directory-pathname (pathname library-name))))
  (lwlgl.core:ensure-native-module :egl)
  (setf *provider*
        (lwlgl.core:make-function-provider
         :name :egl
         :resolver (lambda (name)
                     (lwlgl.core:resolve-foreign-symbol name :module :egl :errorp nil))))
  t)

(defun destroy ()
  (setf *provider* nil)
  (lwlgl.core:unload-native-module :egl)
  nil)

(defun egl-loaded-p () (not (null *provider*)))
(defun get-function-provider () (or *provider* (progn (create) *provider*)))
(defun %function (name) (lwlgl.core:get-function-address (get-function-provider) name :required t))

(defmacro %define-egl-call (checked raw native return-type arguments)
  `(progn
     (defun ,raw ,(mapcar #'first arguments)
       (cffi:foreign-funcall-pointer
        (%function ,native) ()
        ,@(loop for (name type) in arguments append (list type name)) ,return-type))
     (defun ,checked ,(mapcar #'first arguments)
       (,raw ,@(mapcar #'first arguments)))))

(%define-egl-call egl-get-display negl-get-display "eglGetDisplay" :pointer ((display-id :pointer)))
(%define-egl-call egl-initialize negl-initialize "eglInitialize" :unsigned-int
  ((display :pointer) (major :pointer) (minor :pointer)))
(%define-egl-call egl-terminate negl-terminate "eglTerminate" :unsigned-int ((display :pointer)))
(%define-egl-call egl-get-proc-address negl-get-proc-address "eglGetProcAddress" :pointer ((name :string)))
(%define-egl-call egl-get-error negl-get-error "eglGetError" :int ())
(%define-egl-call egl-query-string negl-query-string "eglQueryString" :pointer
  ((display :pointer) (name :int)))

(eval-when (:load-toplevel :execute)
  (do-external-symbols (symbol '#:lwlgl.egl)
    (shadowing-import symbol '#:lwlgl.egl.egl15)
    (export symbol '#:lwlgl.egl.egl15)))
