(require :asdf)

(let* ((source (or *load-truename* *compile-file-truename*
                   *default-pathname-defaults*))
       (root (uiop:pathname-directory-pathname source)))
  (asdf:load-asd (merge-pathnames #P"lwlgl.asd" root))
  (asdf:load-system :lwlgl/examples))

(format t "~&LWLGL ~A carregado com os exemplos. Use (lwlgl.examples:toolbox-demo) para o demo sem dispositivo ou (lwlgl.core:print-runtime-report) para diagnóstico.~%"
        lwlgl.core:*lwlgl-version*)
