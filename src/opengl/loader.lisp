(in-package #:lwlgl.opengl)

(defvar *gl-functions* (make-hash-table :test #'equal))
(defvar *gl-required-functions* '())
(defvar *gl-optional-functions* '())
(defvar *opengl-loaded-p* nil)

(defun opengl-loaded-p () *opengl-loaded-p*)

(defun %resolve-gl-function (name)
  (let ((pointer (lwlgl.glfw:get-proc-address name)))
    (unless (or (null pointer) (cffi:null-pointer-p pointer)) pointer)))

(defun require-gl-function (name)
  (or (gethash name *gl-functions*)
      (error 'lwlgl.core:missing-native-symbol :name name)))

(defun gl-function-available-p (name)
  (let ((pointer (gethash name *gl-functions*)))
    (and pointer (not (cffi:null-pointer-p pointer)))))

(defmacro define-gl-function (lisp-name c-name return-type arguments &key optional)
  "Defines an OpenGL call resolved through glfwGetProcAddress.
OPTIONAL functions are loaded when available but do not make LOAD-OPENGL fail."
  (let ((pointer-var (intern (format nil "*~A-POINTER*" (string-upcase lisp-name)) *package*))
        (function-pointer (gensym "FUNCTION-POINTER")))
    `(progn
       (defvar ,pointer-var nil)
       (eval-when (:load-toplevel :execute)
         (pushnew ,c-name ,(if optional '*gl-optional-functions* '*gl-required-functions*) :test #'string=))
       (defun ,lisp-name ,(mapcar #'first arguments)
         ,(format nil "Dynamic binding for ~A." c-name)
         (let ((,function-pointer (or ,pointer-var (gethash ,c-name *gl-functions*))))
           (unless ,function-pointer
             ,(if optional
                  `(return-from ,lisp-name nil)
                  `(setf ,function-pointer (require-gl-function ,c-name))))
           (cffi:foreign-funcall-pointer
            ,function-pointer ()
            ,@(loop for (name type) in arguments append (list type name))
            ,return-type))))))

(defun load-opengl (&key (error-on-missing t))
  "Resolves all registered OpenGL functions. A current context is required."
  (clrhash *gl-functions*)
  (let ((missing-required '())
        (all (remove-duplicates (append *gl-required-functions* *gl-optional-functions*) :test #'string=)))
    (dolist (name all)
      (let ((pointer (%resolve-gl-function name)))
        (if pointer
            (setf (gethash name *gl-functions*) pointer)
            (when (member name *gl-required-functions* :test #'string=)
              (push name missing-required)))))
    (setf *opengl-loaded-p* t)
    (when (and error-on-missing missing-required)
      (error "Required OpenGL functions missing from the current context: ~{~A~^, ~}"
             (sort missing-required #'string<)))
    (values (null missing-required) (nreverse missing-required))))

(defun reload-opengl (&key (error-on-missing t))
  (setf *opengl-loaded-p* nil)
  (load-opengl :error-on-missing error-on-missing))

(defun gl-capabilities ()
  (sort (loop for name being the hash-keys of *gl-functions* collect name) #'string<))
