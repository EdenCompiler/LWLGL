(in-package #:lwlgl.opengl)

(define-condition shader-error (error)
  ((log :initarg :log :reader shader-error-log))
  (:report (lambda (condition stream)
             (format stream "Shader compilation failed:~%~A" (shader-error-log condition)))))

(define-condition program-error (error)
  ((log :initarg :log :reader program-error-log))
  (:report (lambda (condition stream)
             (format stream "OpenGL program link failed:~%~A" (program-error-log condition)))))

(defun %gen-one (generator)
  (cffi:with-foreign-object (out :unsigned-int)
    (funcall generator 1 out)
    (cffi:mem-ref out :unsigned-int)))

(defun %delete-one (deleter value)
  (when (and value (not (zerop value)))
    (cffi:with-foreign-object (pointer :unsigned-int)
      (setf (cffi:mem-ref pointer :unsigned-int) value)
      (funcall deleter 1 pointer)))
  value)

(defun make-buffer () (%gen-one #'gl-gen-buffers))
(defun delete-buffer (buffer) (%delete-one #'gl-delete-buffers buffer))
(defun make-vertex-array () (%gen-one #'gl-gen-vertex-arrays))
(defun delete-vertex-array (vao) (%delete-one #'gl-delete-vertex-arrays vao))
(defun make-texture () (%gen-one #'gl-gen-textures))
(defun delete-texture (texture) (%delete-one #'gl-delete-textures texture))
(defun make-framebuffer () (%gen-one #'gl-gen-framebuffers))
(defun delete-framebuffer (framebuffer-id) (%delete-one #'gl-delete-framebuffers framebuffer-id))
(defun make-renderbuffer () (%gen-one #'gl-gen-renderbuffers))
(defun delete-renderbuffer (renderbuffer-id) (%delete-one #'gl-delete-renderbuffers renderbuffer-id))

(defun upload-floats (target sequence usage)
  "Uploads SEQUENCE as single-float data to the currently bound buffer."
  (let ((values (map 'vector (lambda (x) (coerce x 'single-float)) sequence)))
    (lwlgl.core:with-foreign-array (pointer :float values)
      (gl-buffer-data target (* (length values) (cffi:foreign-type-size :float)) pointer usage))))

(defun upload-unsigned-ints (target sequence usage)
  (let ((values (coerce sequence 'vector)))
    (lwlgl.core:with-foreign-array (pointer :unsigned-int values)
      (gl-buffer-data target (* (length values) (cffi:foreign-type-size :unsigned-int)) pointer usage))))

(defun upload-buffer-sub-data (target byte-offset sequence &key (type :float))
  "Uploads SEQUENCE into a subrange of the currently bound buffer. BYTE-OFFSET is in bytes."
  (let* ((values (coerce sequence 'vector))
         (size (* (length values) (cffi:foreign-type-size type))))
    (lwlgl.core:with-foreign-array (pointer type values)
      (gl-buffer-sub-data target byte-offset size pointer)))
  target)

(defun %shader-status (shader)
  (cffi:with-foreign-object (status :int)
    (gl-get-shader-iv shader compile-status status)
    (cffi:mem-ref status :int)))

(defun %shader-log (shader)
  (cffi:with-foreign-object (length :int)
    (gl-get-shader-iv shader info-log-length length)
    (let ((size (max 1 (cffi:mem-ref length :int))))
      (cffi:with-foreign-pointer (buffer size)
        (gl-get-shader-info-log shader size (cffi:null-pointer) buffer)
        (cffi:foreign-string-to-lisp buffer :count (max 0 (1- size)))))))

(defun compile-shader (type source)
  (let ((shader (gl-create-shader type)))
    (handler-case
        (progn
          (cffi:with-foreign-string (source-pointer source)
            (cffi:with-foreign-object (source-array :pointer)
              (setf (cffi:mem-ref source-array :pointer) source-pointer)
              (gl-shader-source shader 1 source-array (cffi:null-pointer))))
          (gl-compile-shader shader)
          (unless (= (%shader-status shader) 1)
            (error 'shader-error :log (%shader-log shader)))
          shader)
      (error (condition)
        (gl-delete-shader shader)
        (error condition)))))

(defun %program-status (program)
  (cffi:with-foreign-object (status :int)
    (gl-get-program-iv program link-status status)
    (cffi:mem-ref status :int)))

(defun %program-log (program)
  (cffi:with-foreign-object (length :int)
    (gl-get-program-iv program info-log-length length)
    (let ((size (max 1 (cffi:mem-ref length :int))))
      (cffi:with-foreign-pointer (buffer size)
        (gl-get-program-info-log program size (cffi:null-pointer) buffer)
        (cffi:foreign-string-to-lisp buffer :count (max 0 (1- size)))))))

(defun link-program (&rest shaders)
  (let ((program (gl-create-program)))
    (handler-case
        (progn
          (dolist (shader shaders) (gl-attach-shader program shader))
          (gl-link-program program)
          (unless (= (%program-status program) 1)
            (error 'program-error :log (%program-log program)))
          program)
      (error (condition)
        (gl-delete-program program)
        (error condition)))))

(defun make-program (vertex-source fragment-source)
  "Compiles vertex/fragment shaders, links them, then deletes intermediate shader objects."
  (let ((vertex nil) (fragment nil))
    (unwind-protect
         (progn
           (setf vertex (compile-shader vertex-shader vertex-source)
                 fragment (compile-shader fragment-shader fragment-source))
           (link-program vertex fragment))
      (when vertex (gl-delete-shader vertex))
      (when fragment (gl-delete-shader fragment)))))

(defun get-string (name)
  (let ((pointer (gl-get-string name)))
    (unless (cffi:null-pointer-p pointer)
      (cffi:foreign-string-to-lisp pointer))))

(defun get-integer (name)
  (cffi:with-foreign-object (value :int)
    (gl-get-integer-v name value)
    (cffi:mem-ref value :int)))

(defun gl-extensions ()
  "Returns the current context extension names as a list of strings."
  (let ((count (get-integer num-extensions)))
    (loop for i below count
          for pointer = (gl-get-string-i extensions-string i)
          unless (cffi:null-pointer-p pointer)
            collect (cffi:foreign-string-to-lisp pointer))))

(defun gl-info (&key (include-extensions nil))
  "Returns a plist describing the current OpenGL context."
  (list* :vendor (get-string vendor-string)
         :renderer (get-string renderer-string)
         :version (get-string version-string)
         :shading-language-version (get-string shading-language-version-string)
         :major-version (get-integer major-version)
         :minor-version (get-integer minor-version)
         :max-texture-size (get-integer max-texture-size)
         :max-texture-units (get-integer max-combined-texture-image-units)
         (when include-extensions (list :extensions (gl-extensions)))))

(defun check-error (&optional (context "OpenGL"))
  (let ((code (gl-get-error)))
    (unless (zerop code)
      (error "~A returned OpenGL error 0x~4,'0X." context code))
    code))

(defun set-uniform-mat4 (location matrix &key transpose)
  (unless (lwlgl.math:mat4-p matrix)
    (error "SET-UNIFORM-MAT4 requires an LWLGL.MATH 4x4 matrix."))
  (lwlgl.core:with-foreign-array (pointer :float matrix)
    (gl-uniform-matrix-4fv location 1 (if transpose true-value false-value) pointer)))

(defun set-uniform-mat3 (location matrix &key transpose)
  (unless (= (length matrix) 9)
    (error "SET-UNIFORM-MAT3 requires 9 values."))
  (let ((values (map 'vector (lambda (x) (coerce x 'single-float)) matrix)))
    (lwlgl.core:with-foreign-array (pointer :float values)
      (gl-uniform-matrix-3fv location 1 (if transpose true-value false-value) pointer))))

(defun create-texture-2d (width height pixels &key (format rgba) (internal-format rgba8)
                                                (type unsigned-byte-type)
                                                (min-filter linear) (mag-filter linear)
                                                (wrap-s clamp-to-edge) (wrap-t clamp-to-edge)
                                                generate-mipmaps)
  "Creates and initializes a GL_TEXTURE_2D. PIXELS may be a foreign pointer or NIL."
  (let ((texture (make-texture)))
    (handler-case
        (progn
          (gl-bind-texture texture-2d texture)
          (gl-tex-parameter-i texture-2d texture-min-filter (if generate-mipmaps linear-mipmap-linear min-filter))
          (gl-tex-parameter-i texture-2d texture-mag-filter mag-filter)
          (gl-tex-parameter-i texture-2d texture-wrap-s wrap-s)
          (gl-tex-parameter-i texture-2d texture-wrap-t wrap-t)
          (gl-tex-image-2d texture-2d 0 internal-format width height 0 format type
                           (or pixels (cffi:null-pointer)))
          (when generate-mipmaps (gl-generate-mipmap texture-2d))
          (gl-bind-texture texture-2d 0)
          texture)
      (error (condition)
        (gl-bind-texture texture-2d 0)
        (delete-texture texture)
        (error condition)))))

(defun create-color-framebuffer (width height &key (with-depth-stencil t) (internal-format rgba8))
  "Creates a framebuffer with one 2D color texture and optional depth/stencil renderbuffer.
Returns FBO, COLOR-TEXTURE and RENDERBUFFER (or 0)."
  (let ((fbo (make-framebuffer)) (texture 0) (rbo 0))
    (handler-case
        (progn
          (gl-bind-framebuffer framebuffer fbo)
          (setf texture (create-texture-2d width height nil :internal-format internal-format))
          (gl-framebuffer-texture-2d framebuffer color-attachment0 texture-2d texture 0)
          (when with-depth-stencil
            (setf rbo (make-renderbuffer))
            (gl-bind-renderbuffer renderbuffer rbo)
            (gl-renderbuffer-storage renderbuffer depth24-stencil8 width height)
            (gl-framebuffer-renderbuffer framebuffer depth-stencil-attachment renderbuffer rbo)
            (gl-bind-renderbuffer renderbuffer 0))
          (let ((status (gl-check-framebuffer-status framebuffer)))
            (unless (= status framebuffer-complete)
              (error "Framebuffer incomplete: status 0x~X" status)))
          (gl-bind-framebuffer framebuffer 0)
          (values fbo texture rbo))
      (error (condition)
        (gl-bind-framebuffer framebuffer 0)
        (when (plusp rbo) (delete-renderbuffer rbo))
        (when (plusp texture) (delete-texture texture))
        (delete-framebuffer fbo)
        (error condition)))))

(defun read-pixels-rgba (x y width height)
  "Reads an RGBA8 rectangle from the current framebuffer into an (UNSIGNED-BYTE 8) vector."
  (let* ((count (* width height 4))
         (result (make-array count :element-type '(unsigned-byte 8))))
    (cffi:with-foreign-object (pointer :unsigned-char count)
      (gl-pixel-store-i pack-alignment 1)
      (gl-read-pixels x y width height rgba unsigned-byte-type pointer)
      (dotimes (i count result)
        (setf (aref result i) (cffi:mem-aref pointer :unsigned-char i))))))

(defmacro with-bound-buffer ((target buffer) &body body)
  `(progn
     (gl-bind-buffer ,target ,buffer)
     (unwind-protect (progn ,@body)
       (gl-bind-buffer ,target 0))))

(defmacro with-bound-vertex-array ((vao) &body body)
  `(progn
     (gl-bind-vertex-array ,vao)
     (unwind-protect (progn ,@body)
       (gl-bind-vertex-array 0))))

(defmacro with-bound-texture ((target texture &key (unit texture0)) &body body)
  `(progn
     (gl-active-texture ,unit)
     (gl-bind-texture ,target ,texture)
     (unwind-protect (progn ,@body)
       (gl-bind-texture ,target 0))))

(defmacro with-bound-framebuffer ((target framebuffer-id) &body body)
  `(progn
     (gl-bind-framebuffer ,target ,framebuffer-id)
     (unwind-protect (progn ,@body)
       (gl-bind-framebuffer ,target 0))))

(defmacro with-program ((program) &body body)
  `(progn
     (gl-use-program ,program)
     (unwind-protect (progn ,@body)
       (gl-use-program 0))))

(defun make-query ()
  (unless (gl-function-available-p "glGenQueries")
    (error "OpenGL query objects are not available in this context."))
  (%gen-one #'gl-gen-queries))

(defun delete-query (query)
  (unless (gl-function-available-p "glDeleteQueries")
    (error "OpenGL query objects are not available in this context."))
  (%delete-one #'gl-delete-queries query))

(defun query-result-available-p (query)
  (unless (gl-function-available-p "glGetQueryObjectiv")
    (error "OpenGL query objects are not available in this context."))
  (cffi:with-foreign-object (value :int)
    (gl-get-query-object-iv query query-result-available value)
    (not (zerop (cffi:mem-ref value :int)))))

(defun query-result-ui64 (query &key (wait t))
  "Returns a 64-bit query result. With WAIT=NIL, returns NIL until the result becomes available."
  (unless (gl-function-available-p "glGetQueryObjectui64v")
    (error "64-bit OpenGL query results are not available in this context."))
  (when (and (not wait) (not (query-result-available-p query)))
    (return-from query-result-ui64 nil))
  (cffi:with-foreign-object (value :uint64)
    (gl-get-query-object-ui64v query query-result value)
    (cffi:mem-ref value :uint64)))

(defmacro with-query ((query target) &body body)
  "Begins TARGET query using QUERY, guarantees GL-END-QUERY, then executes BODY."
  `(progn
     (gl-begin-query ,target ,query)
     (unwind-protect (progn ,@body)
       (gl-end-query ,target))))

(defun make-fence (&key (condition sync-gpu-commands-complete) (flags 0))
  (unless (gl-function-available-p "glFenceSync")
    (error "OpenGL sync objects are not available in this context."))
  (gl-fence-sync condition flags))

(defun delete-fence (fence)
  (when (and fence (not (cffi:null-pointer-p fence)))
    (gl-delete-sync fence))
  nil)

(defun wait-fence (fence &key (timeout-nanoseconds 1000000000) flush)
  "Waits on FENCE from the client. Returns one of ALREADY-SIGNALED, TIMEOUT-EXPIRED,
CONDITION-SATISFIED or WAIT-FAILED."
  (unless (gl-function-available-p "glClientWaitSync")
    (error "OpenGL sync objects are not available in this context."))
  (gl-client-wait-sync fence (if flush sync-flush-commands-bit 0) timeout-nanoseconds))

(defmacro with-fence ((var &rest options) &body body)
  `(let ((,var (make-fence ,@options)))
     (unwind-protect (progn ,@body)
       (delete-fence ,var))))
