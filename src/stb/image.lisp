(in-package #:lwlgl.stb)

(lwlgl.core:register-native-module
 :lwlgl-stb
 (lwlgl.core:platform-library-names
  :windows '("lwlgl_stb.dll")
  :macos '("liblwlgl_stb.dylib" "lwlgl_stb.dylib")
  :linux '("liblwlgl_stb.so" "lwlgl_stb.so")))

(cffi:defcfun ("lwlgl_stbi_load" %stbi-load) :pointer
  (filename :string) (width :pointer) (height :pointer) (channels :pointer) (desired-channels :int))
(cffi:defcfun ("lwlgl_stbi_load_from_memory" %stbi-load-from-memory) :pointer
  (buffer :pointer) (length :int) (width :pointer) (height :pointer) (channels :pointer) (desired-channels :int))
(cffi:defcfun ("lwlgl_stbi_loadf" %stbi-loadf) :pointer
  (filename :string) (width :pointer) (height :pointer) (channels :pointer) (desired-channels :int))
(cffi:defcfun ("lwlgl_stbi_info" %stbi-info) :int
  (filename :string) (width :pointer) (height :pointer) (channels :pointer))
(cffi:defcfun ("lwlgl_stbi_is_hdr" %stbi-is-hdr) :int (filename :string))
(cffi:defcfun ("lwlgl_stbi_free" %stbi-free) :void (data :pointer))
(cffi:defcfun ("lwlgl_stbi_failure_reason" %stbi-failure-reason) :string)
(cffi:defcfun ("lwlgl_stbi_set_flip_vertically_on_load" %stbi-set-flip) :void (flag :int))

(defclass image ()
  ((width :initarg :width :reader image-width)
   (height :initarg :height :reader image-height)
   (channels :initarg :channels :reader image-channels)
   (pixels :initarg :pixels :reader image-pixels)
   (pixel-type :initarg :pixel-type :initform :unsigned-byte :reader image-pixel-type)
   (freed-p :initform nil :accessor %image-freed-p)))

(defun image-freed-p (image) (%image-freed-p image))
(defun %ensure-stb () (lwlgl.core:ensure-native-module :lwlgl-stb))

(defun set-flip-vertically-on-load (value)
  (%ensure-stb)
  (%stbi-set-flip (if value 1 0)))

(defun %make-loaded-image (pixels width height source-channels requested-channels pixel-type source)
  (when (cffi:null-pointer-p pixels)
    (error "stb_image could not load ~A: ~A" source (%stbi-failure-reason)))
  (make-instance 'image
                 :width (cffi:mem-ref width :int)
                 :height (cffi:mem-ref height :int)
                 :channels (if (zerop requested-channels) (cffi:mem-ref source-channels :int) requested-channels)
                 :pixels pixels :pixel-type pixel-type))

(defun load-image (path &key (channels 0))
  "Loads an 8-bit image through stb_image. CHANNELS=0 preserves the file channel count."
  (%ensure-stb)
  (cffi:with-foreign-objects ((width :int) (height :int) (source-channels :int))
    (%make-loaded-image (%stbi-load (namestring path) width height source-channels channels)
                        width height source-channels channels :unsigned-byte path)))

(defun load-image-from-memory (bytes &key (channels 0))
  "Loads an 8-bit image from a Lisp octet vector. stb_image owns the returned decoded pixels."
  (%ensure-stb)
  (let ((data (make-array (length bytes) :element-type '(unsigned-byte 8) :initial-contents bytes)))
    (cffi:with-foreign-objects ((width :int) (height :int) (source-channels :int)
                                (pointer :unsigned-char (length data)))
      (dotimes (i (length data))
        (setf (cffi:mem-aref pointer :unsigned-char i) (aref data i)))
      (%make-loaded-image (%stbi-load-from-memory pointer (length data) width height source-channels channels)
                          width height source-channels channels :unsigned-byte "memory buffer"))))

(defun load-hdr-image (path &key (channels 0))
  "Loads an HDR image as 32-bit float components."
  (%ensure-stb)
  (cffi:with-foreign-objects ((width :int) (height :int) (source-channels :int))
    (%make-loaded-image (%stbi-loadf (namestring path) width height source-channels channels)
                        width height source-channels channels :float path)))

(defun image-info (path)
  "Returns WIDTH, HEIGHT and CHANNELS without fully decoding the image."
  (%ensure-stb)
  (cffi:with-foreign-objects ((width :int) (height :int) (channels :int))
    (unless (plusp (%stbi-info (namestring path) width height channels))
      (error "stb_image could not inspect ~A: ~A" path (%stbi-failure-reason)))
    (values (cffi:mem-ref width :int) (cffi:mem-ref height :int) (cffi:mem-ref channels :int))))

(defun hdr-image-p (path)
  (%ensure-stb)
  (plusp (%stbi-is-hdr (namestring path))))

(defun image-byte-size (image)
  (* (image-width image) (image-height image) (image-channels image)
     (ecase (image-pixel-type image) (:unsigned-byte 1) (:float 4))))

(defun free-image (image)
  (unless (%image-freed-p image)
    (%stbi-free (image-pixels image))
    (setf (%image-freed-p image) t))
  image)

(defmacro with-image ((var path &rest options) &body body)
  `(let ((,var (load-image ,path ,@options)))
     (unwind-protect (progn ,@body)
       (free-image ,var))))
