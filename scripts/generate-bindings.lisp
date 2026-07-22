(require :asdf)

(let* ((source (or *load-truename* *compile-file-truename*
                   *default-pathname-defaults*))
       (scripts-directory (uiop:pathname-directory-pathname source))
       (root (uiop:pathname-parent-directory-pathname scripts-directory))
       (spec-path (merge-pathnames #P"bindings/opengl-bootstrap.sexp" root))
       (output-path (merge-pathnames #P"generated/opengl-bootstrap.lisp" root))
       (check-only (member "--check" (uiop:command-line-arguments) :test #'string=)))
  (asdf:load-asd (merge-pathnames #P"lwlgl.asd" root))
  (asdf:load-system :lwlgl/bindgen)
  (let* ((spec (uiop:symbol-call :lwlgl.bindgen :read-binding-spec spec-path))
         (expected (uiop:symbol-call :lwlgl.bindgen :emit-binding-source spec))
         (actual (and (probe-file output-path) (uiop:read-file-string output-path))))
    (cond
      (check-only
       (unless (and actual (string= expected actual))
         (error "Generated binding is stale: ~A" output-path))
       (format t "Binding output is current (~A).~%"
               (uiop:symbol-call :lwlgl.bindgen :binding-spec-fingerprint spec)))
      ((uiop:symbol-call :lwlgl.bindgen :write-generated-binding spec output-path)
       (format t "Updated ~A.~%" output-path))
      (t
       (format t "Binding output is already current.~%")))))
