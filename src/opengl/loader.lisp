(in-package #:lwlgl.opengl)

(defvar *gl-functions* (make-hash-table :test #'equal)
  "Legacy function table. It aliases the table in *CURRENT-GL-CAPABILITIES* after loading.")
(defvar *gl-required-functions* '())
(defvar *gl-optional-functions* '())
(defvar *gl-function-metadata* (make-hash-table :test #'equal))
(defvar *opengl-loaded-p* nil)

(defstruct (gl-capabilities (:constructor %make-gl-capabilities))
  (functions (make-hash-table :test #'equal) :type hash-table)
  (missing-required '() :type list)
  context-address
  loaded-at)

(defvar *current-gl-capabilities* nil
  "Dynamically active OpenGL dispatch table. Each thread/context may bind its own value.")

(defun opengl-loaded-p ()
  (not (null *current-gl-capabilities*)))

(defun gl-capabilities-complete-p (capabilities)
  (null (gl-capabilities-missing-required capabilities)))

(defun %current-context-address ()
  (let ((pointer (ignore-errors (lwlgl.glfw:current-context))))
    (unless (or (null pointer) (cffi:null-pointer-p pointer))
      (cffi:pointer-address pointer))))

(defun %resolve-gl-function (name)
  (let ((pointer (lwlgl.glfw:get-proc-address name)))
    (unless (or (null pointer) (cffi:null-pointer-p pointer)) pointer)))

(defun %capability-table (&optional capabilities)
  (if capabilities
      (gl-capabilities-functions capabilities)
      (if *current-gl-capabilities*
          (gl-capabilities-functions *current-gl-capabilities*)
          *gl-functions*)))

(defun require-gl-function (name &optional capabilities)
  (or (gethash name (%capability-table capabilities))
      (error 'lwlgl.core:missing-native-symbol :name name)))

(defun gl-function-available-p (name &optional capabilities)
  (let ((pointer (gethash name (%capability-table capabilities))))
    (and pointer (not (cffi:null-pointer-p pointer)))))

(defun gl-function-metadata (name)
  "Returns the generated/declarative metadata plist registered for native NAME."
  (copy-tree (gethash name *gl-function-metadata*)))

(defun registered-gl-functions ()
  "Returns all registered OpenGL function metadata sorted by native name."
  (sort (loop for value being the hash-values of *gl-function-metadata*
              collect (copy-tree value))
        #'string< :key (lambda (entry) (getf entry :native-name))))

(defmacro define-gl-function (lisp-name c-name return-type arguments
                              &key optional version profile extension
                                   (dispatch :context) documentation)
  "Defines LWJGL-style raw NGL-* and checked GL-* entry points with metadata."
  (let* ((name (symbol-name lisp-name))
         (raw-p (and (> (length name) 2) (string= name "NGL" :end1 3 :end2 3)))
         (checked-name (if raw-p
                           (intern (subseq name 1) *package*)
                           lisp-name))
         (raw-name (if raw-p lisp-name
                       (intern (concatenate 'string "N" name) *package*)))
         (parameters (mapcar #'first arguments))
         (function-pointer (gensym "FUNCTION-POINTER")))
    `(progn
       (eval-when (:compile-toplevel :load-toplevel :execute)
         (export ',raw-name '#:lwlgl.opengl)
         (pushnew ,c-name ,(if optional '*gl-optional-functions* '*gl-required-functions*)
                  :test #'string=)
         (setf (gethash ,c-name *gl-function-metadata*)
               (list :lisp-name ',checked-name :raw-name ',raw-name :native-name ,c-name
                     :return-type ',return-type :arguments ',arguments
                     :optional ,(not (null optional)) :version ',version
                     :profile ',profile :extension ',extension
                     :dispatch ',dispatch :documentation ,documentation)))
       (defun ,raw-name ,parameters
         ,(format nil "Capability-dispatched binding for ~A." c-name)
         (let ((,function-pointer (gethash ,c-name (%capability-table))))
           (unless ,function-pointer
             ,(if optional
                  `(return-from ,raw-name nil)
                  `(setf ,function-pointer (require-gl-function ,c-name))))
           (cffi:foreign-funcall-pointer
            ,function-pointer ()
            ,@(loop for (name type) in arguments append (list type name))
            ,return-type)))
       ,@(unless raw-p
           `((defun ,checked-name ,parameters
               ,(format nil "Checked entry point corresponding to ~A." c-name)
               (,raw-name ,@parameters)))))))

(defun create-gl-capabilities (&key (error-on-missing t))
  "Resolves registered commands for the context current on this thread."
  (let* ((functions (make-hash-table :test #'equal))
         (missing-required '())
         (all (remove-duplicates
               (append *gl-required-functions* *gl-optional-functions*) :test #'string=)))
    (dolist (name all)
      (let ((pointer (%resolve-gl-function name)))
        (if pointer
            (setf (gethash name functions) pointer)
            (when (member name *gl-required-functions* :test #'string=)
              (push name missing-required)))))
    (setf missing-required (sort missing-required #'string<))
    (let ((capabilities
            (%make-gl-capabilities
             :functions functions :missing-required missing-required
             :context-address (%current-context-address)
             :loaded-at (get-internal-real-time))))
      (when (and error-on-missing missing-required)
        (error "Required OpenGL functions missing from the current context: ~{~A~^, ~}"
               missing-required))
      capabilities)))

(defmacro with-gl-capabilities ((capabilities) &body body)
  "Executes BODY using CAPABILITIES for OpenGL command dispatch."
  (let ((value (gensym "CAPABILITIES"))
        (current (gensym "CURRENT-CONTEXT")))
    `(let* ((,value ,capabilities)
            (,current (%current-context-address)))
       (when (and (lwlgl.core:runtime-configuration-checks-enabled-p
                   lwlgl.core:*runtime-configuration*)
                  (gl-capabilities-context-address ,value)
                  (not (eql ,current (gl-capabilities-context-address ,value))))
         (error "OpenGL capabilities belong to context address ~S, but ~S is current."
                (gl-capabilities-context-address ,value) ,current))
       (let ((*current-gl-capabilities* ,value))
         ,@body))))

(defun create-capabilities (&key (error-on-missing t))
  (create-gl-capabilities :error-on-missing error-on-missing))

(defun get-capabilities ()
  (or *current-gl-capabilities* (error "No OpenGL capabilities are active.")))

(defun set-capabilities (capabilities)
  (setf *current-gl-capabilities* capabilities
        *gl-functions* (gl-capabilities-functions capabilities)
        *opengl-loaded-p* (not (null capabilities)))
  capabilities)

(defmacro with-capabilities ((capabilities) &body body)
  `(with-gl-capabilities (,capabilities) ,@body))

(defun load-opengl (&key (error-on-missing t))
  "Creates and activates capabilities for the current context.
Returns success, missing required names, and the capability object."
  (let ((capabilities (create-gl-capabilities :error-on-missing error-on-missing)))
    (setf *current-gl-capabilities* capabilities
          *gl-functions* (gl-capabilities-functions capabilities)
          *opengl-loaded-p* t)
    (values (null (gl-capabilities-missing-required capabilities))
            (copy-list (gl-capabilities-missing-required capabilities))
            capabilities)))

(defun reload-opengl (&key (error-on-missing t))
  (setf *opengl-loaded-p* nil
        *current-gl-capabilities* nil
        *gl-functions* (make-hash-table :test #'equal))
  (load-opengl :error-on-missing error-on-missing))

(defun gl-capabilities (&optional capabilities)
  "Returns available command names for CAPABILITIES or the active context."
  (sort (loop for name being the hash-keys of (%capability-table capabilities)
              collect name)
        #'string<))
