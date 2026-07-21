(require :asdf)

(let* ((source (or *load-truename* *compile-file-truename* *default-pathname-defaults*))
       (root (uiop:pathname-directory-pathname source)))
  (asdf:load-asd (merge-pathnames #P"lwlgl.asd" root))
  (asdf:load-system :lwlgl/tests)
  (asdf:test-system :lwlgl/tests))
