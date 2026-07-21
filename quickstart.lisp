(require :asdf)

(let* ((source (or *load-truename* *compile-file-truename*
                   *default-pathname-defaults*))
       (root (uiop:pathname-directory-pathname source)))
  (asdf:load-asd (merge-pathnames #P"lwlgl.asd" root))
  (asdf:load-system :lwlgl))

(format t "~&LWLGL ~A carregado. Use (lwlgl.core:print-runtime-report) para diagnóstico.~%"
        lwlgl.core:*lwlgl-version*)
