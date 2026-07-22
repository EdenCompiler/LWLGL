(in-package #:lwlgl.glfw)

(defclass window ()
  ((handle :initarg :handle :reader window-handle)
   (title :initarg :title :accessor window-title)
   (width :initarg :width :accessor window-width)
   (height :initarg :height :accessor window-height)
   (destroyed-p :initform nil :accessor %window-destroyed-p)))

(defvar *windows-by-address* (make-hash-table :test #'eql))
(defvar *key-handlers* (make-hash-table :test #'eql))
(defvar *char-handlers* (make-hash-table :test #'eql))
(defvar *framebuffer-handlers* (make-hash-table :test #'eql))
(defvar *window-size-handlers* (make-hash-table :test #'eql))
(defvar *cursor-handlers* (make-hash-table :test #'eql))
(defvar *scroll-handlers* (make-hash-table :test #'eql))
(defvar *mouse-button-handlers* (make-hash-table :test #'eql))
(defvar *focus-handlers* (make-hash-table :test #'eql))
(defvar *close-handlers* (make-hash-table :test #'eql))
(defvar *drop-handlers* (make-hash-table :test #'eql))

(defun %address (pointer) (cffi:pointer-address pointer))
(defun raw-window-pointer (window) (window-handle window))
(defun %lookup-window (pointer) (gethash (%address pointer) *windows-by-address*))

(defun %call-handlers (table pointer &rest arguments)
  (dolist (handler (copy-list (gethash (%address pointer) table)))
    (apply handler (%lookup-window pointer) arguments)))

(defun %set-handler (table window function installer callback)
  (let ((address (%address (window-handle window))))
    (setf (gethash address table) (if function (list function) nil))
    (funcall installer (window-handle window) (if function callback (cffi:null-pointer))))
  function)

(defun %add-handler (table window function installer callback)
  (pushnew function (gethash (%address (window-handle window)) table) :test #'eq)
  (funcall installer (window-handle window) callback)
  function)

(defun %remove-handler (table window function)
  (setf (gethash (%address (window-handle window)) table)
        (delete function (gethash (%address (window-handle window)) table) :test #'eq))
  function)

(cffi:defcallback %key-callback :void
    ((pointer :pointer) (key :int) (scancode :int) (action :int) (mods :int))
  (%call-handlers *key-handlers* pointer key scancode action mods))

(cffi:defcallback %char-callback :void ((pointer :pointer) (codepoint :unsigned-int))
  (%call-handlers *char-handlers* pointer codepoint))

(cffi:defcallback %framebuffer-size-callback :void ((pointer :pointer) (width :int) (height :int))
  (%call-handlers *framebuffer-handlers* pointer width height))

(cffi:defcallback %window-size-callback :void ((pointer :pointer) (width :int) (height :int))
  (let ((window (%lookup-window pointer)))
    (when window
      (setf (window-width window) width
            (window-height window) height)))
  (%call-handlers *window-size-handlers* pointer width height))

(cffi:defcallback %cursor-position-callback :void ((pointer :pointer) (x :double) (y :double))
  (%call-handlers *cursor-handlers* pointer x y))

(cffi:defcallback %scroll-callback :void ((pointer :pointer) (xoffset :double) (yoffset :double))
  (%call-handlers *scroll-handlers* pointer xoffset yoffset))

(cffi:defcallback %mouse-button-callback :void ((pointer :pointer) (button :int) (action :int) (mods :int))
  (%call-handlers *mouse-button-handlers* pointer button action mods))

(cffi:defcallback %focus-callback :void ((pointer :pointer) (focused-value :int))
  (%call-handlers *focus-handlers* pointer (not (zerop focused-value))))

(cffi:defcallback %close-callback :void ((pointer :pointer))
  (%call-handlers *close-handlers* pointer))

(cffi:defcallback %drop-callback :void ((pointer :pointer) (count :int) (paths :pointer))
  (let ((files (loop for i below count
                     for path-pointer = (cffi:mem-aref paths :pointer i)
                     collect (cffi:foreign-string-to-lisp path-pointer))))
    (%call-handlers *drop-handlers* pointer files)))

(defun %monitor-pointer (monitor)
  (cond ((null monitor) (cffi:null-pointer))
        ((typep monitor 'monitor) (monitor-handle monitor))
        (t monitor)))

(defun %share-pointer (share)
  (cond ((null share) (cffi:null-pointer))
        ((typep share 'window) (window-handle share))
        (t share)))

(defun create-window (width height title &key monitor share)
  (%ensure-glfw)
  (let ((pointer (%glfw-create-window width height title (%monitor-pointer monitor) (%share-pointer share))))
    (when (cffi:null-pointer-p pointer)
      (multiple-value-bind (code description) (last-error)
        (if (zerop code)
            (error "GLFW could not create window ~S (~Ax~A)." title width height)
            (error "GLFW could not create window ~S (~Ax~A). [~X] ~A"
                   title width height code (or description "No GLFW description.")))))
    (let ((window (make-instance 'window :handle pointer :title title :width width :height height)))
      (setf (gethash (%address pointer) *windows-by-address*) window)
      ;; Keep logical dimensions synchronized even if the user does not install a handler.
      (%glfw-set-window-size-callback pointer (cffi:callback %window-size-callback))
      window)))

(defun destroy-window (window)
  (unless (%window-destroyed-p window)
    (let ((address (%address (window-handle window))))
      (dolist (table (list *windows-by-address* *key-handlers* *char-handlers*
                           *framebuffer-handlers* *window-size-handlers* *cursor-handlers*
                           *scroll-handlers* *mouse-button-handlers* *focus-handlers*
                           *close-handlers* *drop-handlers*))
        (remhash address table))
      (%glfw-destroy-window (window-handle window))
      (setf (%window-destroyed-p window) t)))
  window)

(defun make-context-current (window)
  (%glfw-make-context-current (if window (window-handle window) (cffi:null-pointer))))

(defun current-context ()
  "Returns the native pointer of the OpenGL/OpenGL ES context current on this thread."
  (%glfw-get-current-context))

(defun swap-buffers (window) (%glfw-swap-buffers (window-handle window)))
(defun window-should-close-p (window) (not (zerop (%glfw-window-should-close (window-handle window)))))
(defun set-window-should-close (window value)
  (%glfw-set-window-should-close (window-handle window) (if value true false)))

(defun framebuffer-size (window)
  (cffi:with-foreign-objects ((width :int) (height :int))
    (%glfw-get-framebuffer-size (window-handle window) width height)
    (values (cffi:mem-ref width :int) (cffi:mem-ref height :int))))

(defun window-size (window)
  (cffi:with-foreign-objects ((width :int) (height :int))
    (%glfw-get-window-size (window-handle window) width height)
    (values (cffi:mem-ref width :int) (cffi:mem-ref height :int))))

(defun set-window-size (window width height)
  (%glfw-set-window-size (window-handle window) width height)
  window)

(defun window-position (window)
  (cffi:with-foreign-objects ((x :int) (y :int))
    (%glfw-get-window-pos (window-handle window) x y)
    (values (cffi:mem-ref x :int) (cffi:mem-ref y :int))))

(defun set-window-position (window x y)
  (%glfw-set-window-pos (window-handle window) x y)
  window)

(defun set-window-title (window title)
  (%glfw-set-window-title (window-handle window) title)
  (setf (window-title window) title)
  window)

(defun show-window (window) (%glfw-show-window (window-handle window)) window)
(defun hide-window (window) (%glfw-hide-window (window-handle window)) window)
(defun focus-window (window) (%glfw-focus-window (window-handle window)) window)
(defun iconify-window (window) (%glfw-iconify-window (window-handle window)) window)
(defun restore-window (window) (%glfw-restore-window (window-handle window)) window)
(defun maximize-window (window) (%glfw-maximize-window (window-handle window)) window)
(defun window-attrib (window attrib) (%glfw-get-window-attrib (window-handle window) attrib))

(defun window-content-scale (window)
  (cffi:with-foreign-objects ((xscale :float) (yscale :float))
    (%glfw-get-window-content-scale (window-handle window) xscale yscale)
    (values (cffi:mem-ref xscale :float) (cffi:mem-ref yscale :float))))

(defun window-opacity (window) (%glfw-get-window-opacity (window-handle window)))

(defun set-window-opacity (window opacity)
  (%glfw-set-window-opacity (window-handle window) (coerce opacity 'single-float))
  window)

(defun request-window-attention (window)
  (%glfw-request-window-attention (window-handle window))
  window)

(defun create-window-surface (instance window &key allocator)
  "Creates a Vulkan surface for WINDOW. INSTANCE is a VkInstance foreign pointer.
Returns VkResult and VkSurfaceKHR as two values. The caller owns the surface."
  (cffi:with-foreign-object (surface :uint64)
    (let ((result (%glfw-create-window-surface instance (window-handle window)
                                                (or allocator (cffi:null-pointer)) surface)))
      (values result (cffi:mem-ref surface :uint64)))))

(defun get-key (window key) (%glfw-get-key (window-handle window) key))
(defun get-mouse-button (window button) (%glfw-get-mouse-button (window-handle window) button))

(defun cursor-position (window)
  (cffi:with-foreign-objects ((x :double) (y :double))
    (%glfw-get-cursor-pos (window-handle window) x y)
    (values (cffi:mem-ref x :double) (cffi:mem-ref y :double))))

(defun set-cursor-position (window x y)
  (%glfw-set-cursor-pos (window-handle window) (coerce x 'double-float) (coerce y 'double-float))
  window)

(defun get-input-mode (window mode) (%glfw-get-input-mode (window-handle window) mode))
(defun set-input-mode (window mode value) (%glfw-set-input-mode (window-handle window) mode value) window)
(defun raw-mouse-motion-supported-p () (not (zerop (%glfw-raw-mouse-motion-supported))))

(defun set-clipboard-string (window string)
  (%glfw-set-clipboard-string (window-handle window) string)
  string)

(defun clipboard-string (window)
  (let ((pointer (%glfw-get-clipboard-string (window-handle window))))
    (unless (cffi:null-pointer-p pointer)
      (cffi:foreign-string-to-lisp pointer))))

(defmacro %define-handler-api (name table installer callback)
  (let ((set-name (intern (format nil "SET-~A-HANDLER" name) *package*))
        (add-name (intern (format nil "ADD-~A-HANDLER" name) *package*))
        (remove-name (intern (format nil "REMOVE-~A-HANDLER" name) *package*)))
    `(progn
       (defun ,set-name (window function)
         (%set-handler ,table window function #',installer (cffi:callback ,callback)))
       (defun ,add-name (window function)
         (%add-handler ,table window function #',installer (cffi:callback ,callback)))
       (defun ,remove-name (window function)
         (%remove-handler ,table window function)))))

(%define-handler-api key *key-handlers* %glfw-set-key-callback %key-callback)
(%define-handler-api char *char-handlers* %glfw-set-char-callback %char-callback)
(%define-handler-api framebuffer-size *framebuffer-handlers* %glfw-set-framebuffer-size-callback %framebuffer-size-callback)
(%define-handler-api window-size *window-size-handlers* %glfw-set-window-size-callback %window-size-callback)
(%define-handler-api cursor-position *cursor-handlers* %glfw-set-cursor-pos-callback %cursor-position-callback)
(%define-handler-api scroll *scroll-handlers* %glfw-set-scroll-callback %scroll-callback)
(%define-handler-api mouse-button *mouse-button-handlers* %glfw-set-mouse-button-callback %mouse-button-callback)
(%define-handler-api focus *focus-handlers* %glfw-set-window-focus-callback %focus-callback)
(%define-handler-api close *close-handlers* %glfw-set-window-close-callback %close-callback)
(%define-handler-api drop *drop-handlers* %glfw-set-drop-callback %drop-callback)

(defmacro with-glfw (() &body body)
  "Initializes GLFW for BODY and guarantees termination.
On SBCL the dynamic extent also masks host floating-point traps that native window,
OpenGL and driver code may raise internally; the caller's previous FP mode is restored afterwards."
  `(with-native-floating-point-environment ()
     (unless (init)
       (multiple-value-bind (code description) (last-error)
         (if (zerop code)
             (error "Failed to initialize GLFW. Diagnostics: ~S" (glfw-diagnostics))
             (error "Failed to initialize GLFW. [~X] ~A Diagnostics: ~S"
                    code (or description "No GLFW description.") (glfw-diagnostics)))))
     (unwind-protect (progn ,@body)
       (terminate))))

(defmacro with-window ((var width height title &rest args) &body body)
  `(let ((,var (create-window ,width ,height ,title ,@args)))
     (unwind-protect (progn ,@body)
       (destroy-window ,var))))

(defun run-loop (window frame-function &key update-function (poll-events-p t) before-frame after-frame)
  "Runs a minimal render loop without imposing an engine architecture.
BEFORE-FRAME and AFTER-FRAME are optional hooks; UPDATE-FUNCTION runs before rendering."
  (loop until (window-should-close-p window)
        do (when before-frame (funcall before-frame window))
           (when update-function (funcall update-function window))
           (funcall frame-function window)
           (swap-buffers window)
           (when poll-events-p (poll-events))
           (when after-frame (funcall after-frame window))))
