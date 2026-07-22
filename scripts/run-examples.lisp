(require :asdf)

(let* ((source (or *load-truename* *compile-file-truename*
                   *default-pathname-defaults*))
       (scripts-directory (uiop:pathname-directory-pathname source))
       (root (uiop:pathname-parent-directory-pathname scripts-directory)))
  (asdf:load-asd (merge-pathnames #P"lwlgl.asd" root))
  (asdf:load-system :lwlgl/examples))

(let* ((arguments (uiop:command-line-arguments))
       (smoke-p (member "--smoke" arguments :test #'string=))
       (names (remove-if (lambda (argument) (uiop:string-prefix-p "--" argument))
                         arguments))
       (examples
         (list
          (cons "toolbox" #'lwlgl.examples:toolbox-demo)
          (cons "native-memory" #'lwlgl.examples:native-memory-demo)
          (cons "capabilities" #'lwlgl.examples:capabilities-demo)
          (cons "system-info" #'lwlgl.examples:system-info)
          (cons "opengl-info" #'lwlgl.examples:opengl-info)
          (cons "egl-info" #'lwlgl.examples:egl-info)
          (cons "offscreen-framebuffer" #'lwlgl.examples:offscreen-framebuffer)
          (cons "vulkan-readiness" #'lwlgl.examples:vulkan-readiness)
          (cons "hello-window" (lambda ()
                                 (lwlgl.examples:hello-window
                                  :max-frames (and smoke-p 2))))
          (cons "triangle" (lambda ()
                             (lwlgl.examples:triangle
                              :max-frames (and smoke-p 2))))
          (cons "spinning-cube" (lambda ()
                                  (lwlgl.examples:spinning-cube
                                   :max-frames (and smoke-p 2))))
          (cons "textured-quad" (lambda ()
                                  (lwlgl.examples:textured-quad
                                   :max-frames (and smoke-p 2))))
          (cons "instanced-triangles" (lambda ()
                                        (lwlgl.examples:instanced-triangles
                                         :max-frames (and smoke-p 2))))
          (cons "input" (lambda ()
                          (lwlgl.examples:input-demo
                           :max-frames (and smoke-p 2))))
          (cons "audio" (lambda ()
                          (lwlgl.examples:audio-tone
                           :duration (if smoke-p 0.05d0 1.0d0))))
          (cons "positional-audio" (lambda ()
                                     (lwlgl.examples:positional-audio
                                      :duration (if smoke-p 0.10d0 2.0d0)))))))
  (if (null names)
      (format t "~&Available examples:~{ ~A~}~%Use --smoke to bound interactive examples.~%"
              (mapcar #'car examples))
      (dolist (name names)
        (let ((entry (assoc (string-downcase name) examples :test #'string=)))
          (unless entry
            (format *error-output* "~&Unknown example ~S.~%" name)
            (uiop:quit 2))
          (format t "~&=== ~A ===~%" (car entry))
          (handler-case
              (funcall (cdr entry))
            (error (condition)
              (format *error-output* "~&Example ~A failed: ~A~%" name condition)
              (uiop:quit 1)))))))
