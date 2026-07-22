(in-package #:lwlgl.opencl)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter +cl-version-package-names+
    '("LWLGL.OPENCL.CL10" "LWLGL.OPENCL.CL11" "LWLGL.OPENCL.CL12"
      "LWLGL.OPENCL.CL20" "LWLGL.OPENCL.CL21" "LWLGL.OPENCL.CL22"
      "LWLGL.OPENCL.CL30"))
  (dolist (name +cl-version-package-names+)
    (unless (find-package name) (make-package name :use '(#:cl))))
  (labels ((reexport (from to)
             (do-external-symbols (symbol from)
               (shadowing-import symbol to)
               (export symbol to))))
    ;; The currently wrapped discovery commands are all OpenCL 1.0 commands.
    (let ((latest (find-package "LWLGL.OPENCL.CL10")))
      (do-external-symbols (symbol '#:lwlgl.opencl)
        (shadowing-import symbol latest)
        (export symbol latest)))
    (loop for (older newer) on +cl-version-package-names+
          while newer
          when older do (reexport (find-package older) (find-package newer)))))
