(in-package #:lwlgl.glfw)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package "LWLGL.GLFW.GLFW34")
    (make-package "LWLGL.GLFW.GLFW34" :use '(#:cl)))

  (labels ((alias-function (name source package)
             (let ((alias (intern name package)))
               (if (macro-function source)
                   (setf (macro-function alias) (macro-function source))
                   (setf (fdefinition alias) (fdefinition source)))
               (export alias package)))
           (prefixed-name (prefix name)
             (if (uiop:string-prefix-p prefix name)
                 name
                 (format nil "~A-~A" prefix name))))
    (let ((target (find-package "LWLGL.GLFW.GLFW34")))
      ;; Public checked entry points and GLFW-prefixed constants.
      (do-external-symbols (symbol '#:lwlgl.glfw)
        (shadowing-import symbol target)
        (export symbol target)
        (cond
          ((or (fboundp symbol) (macro-function symbol))
           (alias-function (prefixed-name "GLFW" (symbol-name symbol)) symbol target))
          ((constantp symbol)
           (let ((alias (intern (format nil "+GLFW-~A+" (symbol-name symbol)) target)))
             (proclaim `(special ,alias))
             (setf (symbol-value alias) (symbol-value symbol))
             (export alias target)))))
      ;; The CFFI declarations are the pointer-oriented native layer.
      (do-symbols (symbol '#:lwlgl.glfw)
        (let ((name (symbol-name symbol)))
          (when (and (uiop:string-prefix-p "%GLFW-" name) (fboundp symbol))
            (alias-function (format nil "NGLFW-~A" (subseq name 6)) symbol target)))))))
