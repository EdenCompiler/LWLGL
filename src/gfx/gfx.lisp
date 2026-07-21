(in-package #:lwlgl.gfx)

(define-condition shader-include-error (error)
  ((path :initarg :path :reader shader-include-error-path)
   (stack :initarg :stack :reader shader-include-error-stack))
  (:report (lambda (condition stream)
             (format stream "Shader include cycle or missing include at ~A. Stack: ~{~A~^ -> ~}"
                     (shader-include-error-path condition) (shader-include-error-stack condition)))))

(defun %trim (string) (string-trim (list #\Space #\Tab #\Return #\Newline) string))

(defun %include-target (line)
  (let ((trimmed (%trim line)))
    (when (and (>= (length trimmed) 8) (string= "#include" trimmed :end2 8))
      (let* ((rest (%trim (subseq trimmed 8)))
             (length (length rest)))
        (when (>= length 3)
          (cond ((and (char= (char rest 0) #\") (char= (char rest (1- length)) #\"))
                 (subseq rest 1 (1- length)))
                ((and (char= (char rest 0) #\<) (char= (char rest (1- length)) #\>))
                 (subseq rest 1 (1- length)))))))))

(defun %resolve-include (name current-directory include-dirs)
  (or (probe-file (merge-pathnames name current-directory))
      (loop for directory in include-dirs
            for found = (probe-file (merge-pathnames name (uiop:ensure-directory-pathname directory)))
            when found return found)))

(defun %preprocess-file (path include-dirs stack)
  (let* ((true (truename path))
         (name (namestring true)))
    (when (member name stack :test #'string=)
      (error 'shader-include-error :path true :stack (reverse (cons name stack))))
    (let ((directory (uiop:pathname-directory-pathname true))
          (new-stack (cons name stack)))
      (with-output-to-string (out)
        (with-open-file (stream true :direction :input)
          (loop for line = (read-line stream nil nil) while line do
            (let ((include (%include-target line)))
              (if include
                  (let ((resolved (%resolve-include include directory include-dirs)))
                    (unless resolved
                      (error 'shader-include-error :path include :stack (reverse new-stack)))
                    (format out "// begin include: ~A~%~A// end include: ~A~%"
                            include (%preprocess-file resolved include-dirs new-stack) include))
                  (format out "~A~%" line)))))))))

(defun %insert-defines (source defines)
  (if (endp defines) source
      (with-output-to-string (out)
        (with-input-from-string (in source)
          (let ((first (read-line in nil nil)))
            (when first
              (format out "~A~%" first)
              (dolist (definition defines)
                (etypecase definition
                  (string (format out "#define ~A~%" definition))
                  (cons (format out "#define ~A ~A~%" (car definition) (cdr definition)))))
              (loop for line = (read-line in nil nil) while line do (format out "~A~%" line))))))))

(defun preprocess-shader (path &key include-dirs defines)
  "Loads PATH, recursively expands #include \"file\" / <file>, detects cycles and injects optional preprocessor defines after the first line."
  (%insert-defines (%preprocess-file path include-dirs '()) defines))

(defun make-program-from-files (vertex-path fragment-path &key include-dirs defines)
  (lwlgl.opengl:make-program
   (preprocess-shader vertex-path :include-dirs include-dirs :defines defines)
   (preprocess-shader fragment-path :include-dirs include-dirs :defines defines)))

(defun %image-formats (channels srgb)
  (ecase channels
    (1 (values lwlgl.opengl:red lwlgl.opengl:r8))
    (2 (values lwlgl.opengl:rg lwlgl.opengl:rg8))
    (3 (values lwlgl.opengl:rgb (if srgb lwlgl.opengl:srgb8 lwlgl.opengl:rgb8)))
    (4 (values lwlgl.opengl:rgba (if srgb lwlgl.opengl:srgb8-alpha8 lwlgl.opengl:rgba8)))))

(defun load-texture-2d (path &key (flip-vertically t) (srgb nil) (generate-mipmaps t)
                                  (min-filter lwlgl.opengl:linear) (mag-filter lwlgl.opengl:linear)
                                  (wrap-s lwlgl.opengl:clamp-to-edge) (wrap-t lwlgl.opengl:clamp-to-edge))
  "Loads an image with LWLGL.STB and uploads it to a new OpenGL texture. Returns texture, width, height and channels."
  (lwlgl.stb:set-flip-vertically-on-load flip-vertically)
  (lwlgl.stb:with-image (image path)
    (multiple-value-bind (format internal-format) (%image-formats (lwlgl.stb:image-channels image) srgb)
      (values
       (lwlgl.opengl:create-texture-2d
        (lwlgl.stb:image-width image) (lwlgl.stb:image-height image) (lwlgl.stb:image-pixels image)
        :format format :internal-format internal-format
        :generate-mipmaps generate-mipmaps :min-filter min-filter :mag-filter mag-filter
        :wrap-s wrap-s :wrap-t wrap-t)
       (lwlgl.stb:image-width image) (lwlgl.stb:image-height image) (lwlgl.stb:image-channels image)))))

(defstruct gpu-mesh
  (vao 0 :type (unsigned-byte 32))
  (vbo 0 :type (unsigned-byte 32))
  (ebo 0 :type (unsigned-byte 32))
  (index-count 0 :type (integer 0 *)))

(defun upload-obj-mesh (mesh &key (usage lwlgl.opengl:static-draw))
  "Uploads an LWLGL.OBJ mesh and configures locations 0=position, 1=normal, 2=uv."
  (check-type mesh lwlgl.obj:obj-mesh)
  (let ((vao (lwlgl.opengl:make-vertex-array))
        (vbo (lwlgl.opengl:make-buffer))
        (ebo (lwlgl.opengl:make-buffer)))
    (handler-case
        (progn
          (lwlgl.opengl:gl-bind-vertex-array vao)
          (lwlgl.opengl:gl-bind-buffer lwlgl.opengl:array-buffer vbo)
          (lwlgl.opengl:upload-floats lwlgl.opengl:array-buffer (lwlgl.obj:obj-mesh-vertices mesh) usage)
          (lwlgl.opengl:gl-bind-buffer lwlgl.opengl:element-array-buffer ebo)
          (lwlgl.opengl:upload-unsigned-ints lwlgl.opengl:element-array-buffer (lwlgl.obj:obj-mesh-indices mesh) usage)
          (let ((stride (* lwlgl.obj:+obj-vertex-stride-floats+ 4)))
            (lwlgl.opengl:gl-vertex-attrib-pointer 0 3 lwlgl.opengl:float-type lwlgl.opengl:false-value stride (cffi:make-pointer 0))
            (lwlgl.opengl:gl-enable-vertex-attrib-array 0)
            (lwlgl.opengl:gl-vertex-attrib-pointer 1 3 lwlgl.opengl:float-type lwlgl.opengl:false-value stride (cffi:make-pointer 12))
            (lwlgl.opengl:gl-enable-vertex-attrib-array 1)
            (lwlgl.opengl:gl-vertex-attrib-pointer 2 2 lwlgl.opengl:float-type lwlgl.opengl:false-value stride (cffi:make-pointer 24))
            (lwlgl.opengl:gl-enable-vertex-attrib-array 2))
          (lwlgl.opengl:gl-bind-vertex-array 0)
          (make-gpu-mesh :vao vao :vbo vbo :ebo ebo :index-count (length (lwlgl.obj:obj-mesh-indices mesh))))
      (error (condition)
        (lwlgl.opengl:gl-bind-vertex-array 0)
        (when (plusp ebo) (lwlgl.opengl:delete-buffer ebo))
        (when (plusp vbo) (lwlgl.opengl:delete-buffer vbo))
        (when (plusp vao) (lwlgl.opengl:delete-vertex-array vao))
        (error condition)))))

(defun draw-gpu-mesh (mesh &key (mode lwlgl.opengl:triangles))
  (lwlgl.opengl:gl-bind-vertex-array (gpu-mesh-vao mesh))
  (lwlgl.opengl:gl-draw-elements mode (gpu-mesh-index-count mesh) lwlgl.opengl:unsigned-int (cffi:null-pointer))
  (lwlgl.opengl:gl-bind-vertex-array 0)
  mesh)

(defun delete-gpu-mesh (mesh)
  (when (plusp (gpu-mesh-ebo mesh)) (lwlgl.opengl:delete-buffer (gpu-mesh-ebo mesh)))
  (when (plusp (gpu-mesh-vbo mesh)) (lwlgl.opengl:delete-buffer (gpu-mesh-vbo mesh)))
  (when (plusp (gpu-mesh-vao mesh)) (lwlgl.opengl:delete-vertex-array (gpu-mesh-vao mesh)))
  (setf (gpu-mesh-vao mesh) 0 (gpu-mesh-vbo mesh) 0 (gpu-mesh-ebo mesh) 0 (gpu-mesh-index-count mesh) 0)
  mesh)

(defmacro with-gpu-mesh ((var mesh-form &rest upload-args) &body body)
  `(let ((,var (upload-obj-mesh ,mesh-form ,@upload-args)))
     (unwind-protect (progn ,@body)
       (delete-gpu-mesh ,var))))
