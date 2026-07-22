(require :asdf)

(let* ((source (or *load-truename* *compile-file-truename*
                   *default-pathname-defaults*))
       (root (uiop:pathname-directory-pathname source)))
  (asdf:load-asd (merge-pathnames #P"lwlgl.asd" root))
  (asdf:load-system :lwlgl/all)
  (asdf:load-system :lwlgl/examples))

(format t "~&LWLGL ~A carregado com os exemplos. Experimente (lwlgl.examples:spinning-cube), (lwlgl.examples:native-memory-demo) ou scripts/run-examples.lisp.~%"
        lwlgl.core:*lwlgl-version*)
