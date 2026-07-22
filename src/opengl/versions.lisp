(in-package #:lwlgl.opengl)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter +gl-version-package-names+
    '("LWLGL.OPENGL.GL11" "LWLGL.OPENGL.GL12" "LWLGL.OPENGL.GL13"
      "LWLGL.OPENGL.GL14" "LWLGL.OPENGL.GL15" "LWLGL.OPENGL.GL20"
      "LWLGL.OPENGL.GL21" "LWLGL.OPENGL.GL30" "LWLGL.OPENGL.GL31"
      "LWLGL.OPENGL.GL32" "LWLGL.OPENGL.GL33" "LWLGL.OPENGL.GL40"
      "LWLGL.OPENGL.GL41" "LWLGL.OPENGL.GL42" "LWLGL.OPENGL.GL43"
      "LWLGL.OPENGL.GL44" "LWLGL.OPENGL.GL45" "LWLGL.OPENGL.GL46"))
  (defparameter +gl-core-version-package-names+
    (mapcar (lambda (name) (concatenate 'string name "C"))
            +gl-version-package-names+))
  (defparameter +gl-command-introductions+
    '(("GL13" gl-active-texture)
      ("GL14" gl-blend-equation)
      ("GL15" gl-gen-buffers gl-delete-buffers gl-bind-buffer gl-buffer-data
              gl-buffer-sub-data gl-gen-queries gl-delete-queries gl-begin-query
              gl-end-query gl-get-query-object-iv)
      ("GL20" gl-create-shader gl-shader-source gl-compile-shader gl-get-shader-iv
              gl-get-shader-info-log gl-delete-shader gl-create-program gl-attach-shader
              gl-detach-shader gl-link-program gl-get-program-iv gl-get-program-info-log
              gl-use-program gl-delete-program gl-get-attrib-location gl-get-uniform-location
              gl-uniform-1f gl-uniform-2f gl-uniform-3f gl-uniform-4f gl-uniform-1i
              gl-uniform-2i gl-uniform-3i gl-uniform-4i gl-uniform-matrix-3fv
              gl-uniform-matrix-4fv gl-vertex-attrib-pointer
              gl-enable-vertex-attrib-array gl-disable-vertex-attrib-array)
      ("GL30" gl-gen-vertex-arrays gl-delete-vertex-arrays gl-bind-vertex-array
              gl-gen-framebuffers gl-delete-framebuffers gl-bind-framebuffer
              gl-check-framebuffer-status gl-framebuffer-texture-2d gl-blit-framebuffer
              gl-gen-renderbuffers gl-delete-renderbuffers gl-bind-renderbuffer
              gl-renderbuffer-storage gl-framebuffer-renderbuffer gl-generate-mipmap
              gl-get-string-i)
      ("GL31" gl-bind-buffer-base gl-get-uniform-block-index gl-uniform-block-binding
              gl-draw-arrays-instanced gl-draw-elements-instanced)
      ("GL32" gl-fence-sync gl-delete-sync gl-client-wait-sync)
      ("GL33" gl-vertex-attrib-divisor gl-get-query-object-ui64v)))

  (dolist (name (append +gl-version-package-names+ +gl-core-version-package-names+))
    (unless (find-package name) (make-package name :use '(#:cl))))

  (labels ((reexport (from to)
             (do-external-symbols (symbol from)
               (shadowing-import symbol to)
               (export symbol to)))
           (introduction (checked)
             (or (loop for (version . names) in +gl-command-introductions+
                       when (member checked names) return version)
                 "GL11"))
           (publish (symbol package)
             (shadowing-import symbol package)
             (export symbol package)))
    ;; Assign every curated command to its actual core introduction package.
    (dolist (metadata (registered-gl-functions))
      (let* ((checked (getf metadata :lisp-name))
             (raw (getf metadata :raw-name))
             (version (introduction checked)))
        (dolist (suffix '("" "C"))
          (let ((package (find-package
                          (format nil "LWLGL.OPENGL.~A~A" version suffix))))
            (publish checked package)
            (publish raw package)))))
    ;; Constants retain prefixed LWJGL names. The curated constants registry is
    ;; published from GL11 and inherited forward until registry metadata splits it.
    (dolist (package (list (find-package "LWLGL.OPENGL.GL11")
                           (find-package "LWLGL.OPENGL.GL11C")))
      (do-external-symbols (symbol '#:lwlgl.opengl)
        (when (constantp symbol)
          (let ((alias (intern (format nil "+GL-~A+" (symbol-name symbol)) package)))
            (proclaim `(special ,alias))
            (setf (symbol-value alias) (symbol-value symbol))
            (export alias package)))))
    (loop for (older newer) on +gl-version-package-names+
          while newer when older do (reexport (find-package older) (find-package newer)))
    (loop for (older newer) on +gl-core-version-package-names+
          while newer when older do (reexport (find-package older) (find-package newer)))))
