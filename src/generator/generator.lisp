(in-package #:lwlgl.bindgen)

(defstruct binding-argument
  name type (direction :in) count (nullable-p nil))

(defstruct binding-type name native-name cffi-type category)
(defstruct binding-struct name native-name fields union-p version extension)
(defstruct binding-handle name native-name dispatchable-p parent)
(defstruct binding-callback name native-name return-type arguments)
(defstruct binding-feature name api version profile extension requires commands constants types)

(defstruct binding-command
  lisp-name raw-name native-name return-type arguments (optional-p nil)
  version profile extension (dispatch :global) documentation)

(defstruct binding-spec
  name api package revision (definer 'define-gl-function)
  (commands '()) (constants '()) (types '()) (structs '()) (handles '())
  (callbacks '()) (features '()))

(defun %required (plist key context)
  (or (getf plist key)
      (error "Missing ~S in ~A." key context)))

(defun %parse-argument (form)
  (if (and (= (length form) 2) (symbolp (first form)))
      (make-binding-argument :name (first form) :type (second form))
      (make-binding-argument
       :name (%required form :name "binding argument")
       :type (%required form :type "binding argument")
       :direction (or (getf form :direction) :in)
       :count (getf form :count)
       :nullable-p (not (null (getf form :nullable))))))

(defun %raw-name (lisp-name)
  (intern (concatenate 'string "N" (symbol-name lisp-name))
          (or (symbol-package lisp-name) *package*)))

(defun %parse-command (form)
  (let ((lisp-name (%required form :lisp-name "binding command")))
  (make-binding-command
   :lisp-name lisp-name
   :raw-name (or (getf form :raw-name) (%raw-name lisp-name))
   :native-name (%required form :native-name "binding command")
   :return-type (%required form :return-type "binding command")
   :arguments (mapcar #'%parse-argument (or (getf form :arguments) '()))
   :optional-p (not (null (getf form :optional)))
   :version (getf form :version) :profile (getf form :profile)
   :extension (getf form :extension) :dispatch (or (getf form :dispatch) :global)
   :documentation (getf form :documentation))))

(defun read-binding-spec (pathname)
  "Reads a declarative binding specification with *READ-EVAL* disabled."
  (with-open-file (stream pathname :direction :input)
    (let ((*read-eval* nil)
          (form (read stream nil nil)))
      (unless form (error "Empty binding specification: ~A" pathname))
      (let ((spec
              (make-binding-spec
               :name (%required form :name "binding specification")
               :api (%required form :api "binding specification")
               :package (%required form :package "binding specification")
               :revision (%required form :revision "binding specification")
               :definer (or (getf form :definer) 'define-gl-function)
               :commands (mapcar #'%parse-command (or (getf form :commands) '()))
               :constants (copy-tree (or (getf form :constants) '()))
               :types (copy-tree (or (getf form :types) '()))
               :structs (copy-tree (or (getf form :structs) '()))
               :handles (copy-tree (or (getf form :handles) '()))
               :callbacks (copy-tree (or (getf form :callbacks) '()))
               :features (copy-tree (or (getf form :features) '())))))
        (validate-binding-spec spec)
        spec))))

(defun validate-binding-spec (spec)
  "Validates names and function signatures, returning SPEC."
  (let ((lisp-names (make-hash-table :test #'equal))
        (native-names (make-hash-table :test #'equal)))
    (dolist (command (binding-spec-commands spec))
      (unless (symbolp (binding-command-lisp-name command))
        (error "Lisp binding name must be a symbol: ~S" command))
      (unless (stringp (binding-command-native-name command))
        (error "Native binding name must be a string: ~S" command))
      (when (gethash (symbol-name (binding-command-lisp-name command)) lisp-names)
        (error "Duplicate Lisp binding name: ~S" (binding-command-lisp-name command)))
      (when (gethash (binding-command-native-name command) native-names)
        (error "Duplicate native binding name: ~S" (binding-command-native-name command)))
      (setf (gethash (symbol-name (binding-command-lisp-name command)) lisp-names) t
            (gethash (binding-command-native-name command) native-names) t)
      (dolist (argument (binding-command-arguments command))
        (unless (and (symbolp (binding-argument-name argument))
                     (member (binding-argument-direction argument) '(:in :out :in-out)))
          (error "Invalid argument descriptor ~S for ~A."
                 argument (binding-command-native-name command)))))
    (dolist (constant (binding-spec-constants spec))
      (unless (and (listp constant) (= (length constant) 2)
                   (symbolp (first constant)) (integerp (second constant)))
        (error "Invalid constant descriptor: ~S" constant)))
    spec))

(defun %canonical-data (value)
  (cond ((keywordp value) (list :keyword (symbol-name value)))
        ((symbolp value) (list :symbol (symbol-name value)))
        ((consp value) (mapcar #'%canonical-data value))
        (t value)))

(defun %canonical-form (spec)
  (list :name (binding-spec-name spec) :api (binding-spec-api spec)
        :package (binding-spec-package spec) :revision (binding-spec-revision spec)
        :definer (binding-spec-definer spec)
        :constants (binding-spec-constants spec)
        :types (binding-spec-types spec) :structs (binding-spec-structs spec)
        :handles (binding-spec-handles spec) :callbacks (binding-spec-callbacks spec)
        :features (binding-spec-features spec)
        :commands
        (mapcar (lambda (command)
                  (list :lisp-name (binding-command-lisp-name command)
                        :raw-name (binding-command-raw-name command)
                        :native-name (binding-command-native-name command)
                        :return-type (binding-command-return-type command)
                        :arguments
                        (mapcar (lambda (argument)
                                  (list :name (binding-argument-name argument)
                                        :type (binding-argument-type argument)
                                        :direction (binding-argument-direction argument)
                                        :count (binding-argument-count argument)
                                        :nullable (binding-argument-nullable-p argument)))
                                (binding-command-arguments command))
                        :optional (binding-command-optional-p command)
                        :version (binding-command-version command)
                        :profile (binding-command-profile command)
                        :extension (binding-command-extension command)
                        :dispatch (binding-command-dispatch command)
                        :documentation (binding-command-documentation command)))
                (binding-spec-commands spec))))

(defun binding-spec-fingerprint (spec)
  "Returns a deterministic 64-bit FNV-1a fingerprint of SPEC."
  (let ((hash #xcbf29ce484222325))
    (loop for character across (with-output-to-string (stream)
                                 (let ((*print-case* :downcase)
                                       (*print-pretty* nil))
                                   (write (%canonical-data (%canonical-form spec))
                                          :stream stream :readably t)))
          do (setf hash (ldb (byte 64 0)
                             (* (logxor hash (char-code character)) #x100000001b3))))
    (format nil "~16,'0X" hash)))

(defun emit-binding-source (spec &optional stream)
  "Emits deterministic Lisp source. Returns a string when STREAM is NIL."
  (flet ((emit (output)
           (format output ";;;; Generated by LWLGL bindgen; do not edit.~%")
           (format output ";;;; API: ~A; registry revision: ~A; fingerprint: ~A~2%"
                   (binding-spec-api spec) (binding-spec-revision spec)
                   (binding-spec-fingerprint spec))
           (format output "(in-package ~S)~2%" (binding-spec-package spec))
           (dolist (constant (binding-spec-constants spec))
             (format output "(defconstant ~(~A~) ~S)~%"
                     (symbol-name (first constant)) (second constant)))
           (when (binding-spec-constants spec) (terpri output))
           (dolist (command (binding-spec-commands spec))
             (format output "(~(~A~) ~(~A~) ~S ~S~%  ("
                     (symbol-name (binding-spec-definer spec))
                     (symbol-name (binding-command-raw-name command))
                     (binding-command-native-name command)
                     (binding-command-return-type command))
             (loop for argument in (binding-command-arguments command)
                   for first = t then nil
                   unless first do (write-char #\Space output)
                   do (format output "(~(~A~) ~S)"
                              (symbol-name (binding-argument-name argument))
                              (binding-argument-type argument)))
             (format output ")~@[ :optional t~]" (binding-command-optional-p command))
             (when (binding-command-version command)
               (format output " :version ~S" (binding-command-version command)))
             (when (binding-command-profile command)
               (format output " :profile ~S" (binding-command-profile command)))
             (when (binding-command-extension command)
               (format output " :extension ~S" (binding-command-extension command)))
             (unless (eq :global (binding-command-dispatch command))
               (format output " :dispatch ~S" (binding-command-dispatch command)))
             (when (binding-command-documentation command)
               (format output " :documentation ~S" (binding-command-documentation command)))
             (format output ")~%")
             (format output "(defun ~(~A~) ("
                     (symbol-name (binding-command-lisp-name command)))
             (loop for argument in (binding-command-arguments command)
                   for first = t then nil
                   unless first do (write-char #\Space output)
                   do (format output "~(~A~)" (symbol-name (binding-argument-name argument))))
             (format output ") (~(~A~)"
                     (symbol-name (binding-command-raw-name command)))
             (dolist (argument (binding-command-arguments command))
               (format output " ~(~A~)" (symbol-name (binding-argument-name argument))))
             (format output "))~%"))))
    (if stream (emit stream) (with-output-to-string (output) (emit output)))))

(defun write-generated-binding (spec pathname)
  "Writes generated source only when content changed. Returns true on update."
  (let* ((content (emit-binding-source spec))
         (existing (and (probe-file pathname) (uiop:read-file-string pathname))))
    (unless (string= content (or existing ""))
      (ensure-directories-exist pathname)
      (with-open-file (stream pathname :direction :output :if-exists :supersede
                              :if-does-not-exist :create)
        (write-string content stream))
      t)))
