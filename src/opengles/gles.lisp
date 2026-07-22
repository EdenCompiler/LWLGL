(in-package #:lwlgl.opengles)

(defconstant +gl-color-buffer-bit+ #x00004000)
(defconstant +gl-depth-buffer-bit+ #x00000100)
(defconstant +gl-stencil-buffer-bit+ #x00000400)

(defstruct (gles-capabilities (:include lwlgl.core:api-capabilities)
                              (:constructor %make-gles-capabilities)))
(defvar *capabilities* nil)

(defparameter +bootstrap-functions+
  '("glClearColor" "glClear" "glViewport" "glGetError"))

(defun create-capabilities (&key provider)
  (let* ((actual-provider
           (or provider
               (lwlgl.core:make-function-provider
                :name :egl-gles
                :resolver #'lwlgl.egl:egl-get-proc-address)))
         (functions (make-hash-table :test #'equal)))
    (dolist (name +bootstrap-functions+)
      (let ((pointer (lwlgl.core:get-function-address actual-provider name)))
        (when pointer (setf (gethash name functions) pointer))))
    (setf *capabilities*
          (%make-gles-capabilities :api :opengles :version '(3 2)
                                   :functions functions))))

(defun get-capabilities ()
  (or *capabilities* (error "No OpenGL ES capabilities are active.")))
(defun set-capabilities (capabilities) (setf *capabilities* capabilities))
(defmacro with-capabilities ((capabilities) &body body)
  `(let ((*capabilities* ,capabilities)) (locally ,@body)))
(defun gl-function-available-p (name &optional (capabilities (get-capabilities)))
  (not (null (lwlgl.core:capability-function-pointer capabilities name))))
(defun %function (name)
  (lwlgl.core:require-capability-function (get-capabilities) name))

(defmacro %define-gles-call (checked raw native return-type arguments)
  `(progn
     (defun ,raw ,(mapcar #'first arguments)
       (cffi:foreign-funcall-pointer
        (%function ,native) ()
        ,@(loop for (name type) in arguments append (list type name)) ,return-type))
     (defun ,checked ,(mapcar #'first arguments)
       (,raw ,@(mapcar #'first arguments)))))

(%define-gles-call gl-clear-color ngl-clear-color "glClearColor" :void
  ((red :float) (green :float) (blue :float) (alpha :float)))
(%define-gles-call gl-clear ngl-clear "glClear" :void ((mask :unsigned-int)))
(%define-gles-call gl-viewport ngl-viewport "glViewport" :void
  ((x :int) (y :int) (width :int) (height :int)))
(%define-gles-call gl-get-error ngl-get-error "glGetError" :unsigned-int ())

(eval-when (:load-toplevel :execute)
  (labels ((reexport (from to)
             (do-external-symbols (symbol from)
               (shadowing-import symbol to)
               (export symbol to))))
    ;; Every command in the bootstrap surface is part of GLES 2.0.
    (do-external-symbols (symbol '#:lwlgl.opengles)
      (shadowing-import symbol '#:lwlgl.opengles.gles20)
      (export symbol '#:lwlgl.opengles.gles20))
    (reexport '#:lwlgl.opengles.gles20 '#:lwlgl.opengles.gles30)
    (reexport '#:lwlgl.opengles.gles30 '#:lwlgl.opengles.gles31)
    (reexport '#:lwlgl.opengles.gles31 '#:lwlgl.opengles.gles32)))
