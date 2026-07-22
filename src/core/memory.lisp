(in-package #:lwlgl.core)

(defstruct (native-buffer (:constructor %make-native-buffer) (:copier nil))
  pointer
  allocation-pointer
  (length 0 :type (integer 0 *))
  (position 0 :type (integer 0 *))
  (limit 0 :type (integer 0 *))
  element-type
  (element-size 0 :type (integer 0 *))
  (capacity-bytes 0 :type (integer 0 *))
  (alignment 1 :type (integer 1 *))
  (owned-p t :type boolean)
  (read-only-p nil :type boolean)
  parent
  (freed-p nil :type boolean))

(defun %power-of-two-p (value)
  (and (plusp value) (zerop (logand value (1- value)))))

(defun %natural-alignment (element-size)
  ;; The largest power-of-two divisor is a safe default for scalar and struct sizes.
  (max 1 (logand element-size (- element-size))))

(defun %native-zero (element-type)
  (case element-type
    (:float 0.0)
    (:double 0.0d0)
    (:pointer (null-pointer))
    (otherwise 0)))

(defun native-buffer-alive-p (buffer)
  "Returns true when BUFFER and every buffer it views still refer to live memory."
  (and (native-buffer-p buffer)
       (not (native-buffer-freed-p buffer))
       (native-buffer-pointer buffer)
       (not (null-pointer-p (native-buffer-pointer buffer)))
       (or (null (native-buffer-parent buffer))
           (native-buffer-alive-p (native-buffer-parent buffer)))))

(defun %memory-error (buffer control &rest arguments)
  (error 'native-memory-error :buffer buffer
         :reason (apply #'format nil control arguments)))

(defun %check-buffer-live (buffer)
  (when (and (runtime-configuration-checks-enabled-p *runtime-configuration*)
             (not (native-buffer-alive-p buffer)))
    (%memory-error buffer "buffer has been freed or its owner is no longer alive"))
  buffer)

(defun make-native-buffer (element-type length &key (initial-element nil initial-element-p)
                                                   alignment read-only)
  "Allocates an owned, aligned native buffer for LENGTH CFFI elements."
  (check-type length (integer 0 *))
  (let* ((element-size (foreign-type-size element-type))
         (requested-alignment (or alignment (%natural-alignment element-size))))
    (unless (%power-of-two-p requested-alignment)
      (error "Native buffer alignment must be a positive power of two, not ~S."
             requested-alignment))
    (let* ((capacity (* length element-size))
           (allocation-size (+ (max 1 capacity) (1- requested-alignment)))
           (base (foreign-alloc :unsigned-char :count allocation-size))
           (address (pointer-address base))
           (offset (mod (- requested-alignment (mod address requested-alignment))
                        requested-alignment))
           (pointer (inc-pointer base offset))
           (buffer (%make-native-buffer
                    :pointer pointer :allocation-pointer base :length length
                    :position 0 :limit length
                    :element-type element-type :element-size element-size
                    :capacity-bytes capacity :alignment requested-alignment
                    :owned-p t :read-only-p (not (null read-only)))))
      (when initial-element-p
        (dotimes (index length)
          (setf (mem-aref pointer element-type index) initial-element)))
      buffer)))

(defun wrap-native-buffer (pointer element-type length &key owned read-only parent)
  "Wraps POINTER without copying. By default the returned buffer is borrowed."
  (check-type length (integer 0 *))
  (let ((element-size (foreign-type-size element-type)))
    (%make-native-buffer
     :pointer pointer :allocation-pointer (and owned pointer) :length length
     :position 0 :limit length
     :element-type element-type :element-size element-size
     :capacity-bytes (* length element-size) :alignment (max 1 element-size)
     :owned-p (not (null owned)) :read-only-p (not (null read-only)) :parent parent)))

(defun slice-native-buffer (buffer offset &optional length)
  "Returns a borrowed view beginning at element OFFSET."
  (%check-buffer-live buffer)
  (let ((view-length (or length (- (native-buffer-length buffer) offset))))
    (unless (and (integerp offset) (integerp view-length)
                 (<= 0 offset) (<= 0 view-length)
                 (<= (+ offset view-length) (native-buffer-length buffer)))
      (%memory-error buffer "slice [~D, ~D) is outside buffer length ~D"
                     offset (+ offset view-length) (native-buffer-length buffer)))
    (let ((view (wrap-native-buffer
                 (inc-pointer (native-buffer-pointer buffer)
                              (* offset (native-buffer-element-size buffer)))
                 (native-buffer-element-type buffer) view-length
                 :read-only (native-buffer-read-only-p buffer) :parent buffer)))
      (setf (native-buffer-alignment view) (native-buffer-alignment buffer))
      view)))

(defun free-native-buffer (buffer)
  "Frees BUFFER when it owns its allocation. Idempotent; views are invalidated."
  (when (and buffer (native-buffer-owned-p buffer)
             (not (native-buffer-freed-p buffer))
             (native-buffer-allocation-pointer buffer)
             (not (null-pointer-p (native-buffer-allocation-pointer buffer))))
    (foreign-free (native-buffer-allocation-pointer buffer)))
  (when buffer
    (setf (native-buffer-pointer buffer) (null-pointer)
          (native-buffer-allocation-pointer buffer) nil
          (native-buffer-owned-p buffer) nil
          (native-buffer-freed-p buffer) t))
  buffer)

(defun %check-buffer-index (buffer index)
  (%check-buffer-live buffer)
  (unless (and (integerp index) (<= 0 index) (< index (native-buffer-length buffer)))
    (%memory-error buffer "index ~A is outside [0, ~A)"
                   index (native-buffer-length buffer))))

(defun buffer-ref (buffer index)
  (%check-buffer-index buffer index)
  (mem-aref (native-buffer-pointer buffer) (native-buffer-element-type buffer) index))

(defun buffer-set (buffer index value)
  (%check-buffer-index buffer index)
  (when (and (runtime-configuration-checks-enabled-p *runtime-configuration*)
             (native-buffer-read-only-p buffer))
    (%memory-error buffer "buffer is read-only"))
  (setf (mem-aref (native-buffer-pointer buffer) (native-buffer-element-type buffer) index)
        value))

(defun native-buffer-remaining (buffer)
  (%check-buffer-live buffer)
  (- (native-buffer-limit buffer) (native-buffer-position buffer)))

(defun buffer-get (buffer)
  "Reads at BUFFER's position and advances it by one element."
  (let ((position (native-buffer-position buffer)))
    (when (>= position (native-buffer-limit buffer))
      (%memory-error buffer "buffer underflow at position ~D" position))
    (prog1 (buffer-ref buffer position)
      (incf (native-buffer-position buffer)))))

(defun buffer-put (buffer value)
  "Writes at BUFFER's position, advances it, and returns BUFFER."
  (let ((position (native-buffer-position buffer)))
    (when (>= position (native-buffer-limit buffer))
      (%memory-error buffer "buffer overflow at position ~D" position))
    (buffer-set buffer position value)
    (incf (native-buffer-position buffer)))
  buffer)

(defun clear-native-buffer (buffer)
  "Prepares BUFFER for writing without modifying its memory."
  (%check-buffer-live buffer)
  (setf (native-buffer-position buffer) 0
        (native-buffer-limit buffer) (native-buffer-length buffer))
  buffer)

(defun flip-native-buffer (buffer)
  "Sets the limit to the current position and rewinds for reading."
  (%check-buffer-live buffer)
  (setf (native-buffer-limit buffer) (native-buffer-position buffer)
        (native-buffer-position buffer) 0)
  buffer)

(defun rewind-native-buffer (buffer)
  (%check-buffer-live buffer)
  (setf (native-buffer-position buffer) 0)
  buffer)

(defsetf buffer-ref (buffer index) (value)
  `(buffer-set ,buffer ,index ,value))

(defun fill-native-buffer (buffer value &key (start 0) end)
  "Fills BUFFER elements in [START, END) with VALUE."
  (let ((limit (or end (native-buffer-length buffer))))
    (unless (and (integerp start) (integerp limit)
                 (<= 0 start limit (native-buffer-length buffer)))
      (%memory-error buffer "invalid fill range [~A, ~A)" start limit))
    (loop for index from start below limit do (buffer-set buffer index value)))
  buffer)

(defun copy-native-buffer (source destination &key (source-start 0) (destination-start 0) count)
  "Copies elements between same-typed buffers and returns DESTINATION."
  (%check-buffer-live source)
  (%check-buffer-live destination)
  (unless (equal (native-buffer-element-type source)
                 (native-buffer-element-type destination))
    (%memory-error destination "source and destination element types differ"))
  (let ((amount (or count (min (- (native-buffer-length source) source-start)
                               (- (native-buffer-length destination) destination-start)))))
    (unless (and (integerp source-start) (integerp destination-start) (integerp amount)
                 (<= 0 source-start) (<= 0 destination-start) (<= 0 amount)
                 (<= (+ source-start amount) (native-buffer-length source))
                 (<= (+ destination-start amount) (native-buffer-length destination)))
      (%memory-error destination "copy range is outside source or destination"))
    ;; Element-wise copying is portable and handles overlapping views correctly.
    (let ((values (loop for index below amount
                        collect (buffer-ref source (+ source-start index)))))
      (loop for value in values for index from destination-start
            do (buffer-set destination index value))))
  destination)

(defmacro with-native-buffer ((var element-type length &rest options) &body body)
  `(let ((,var (make-native-buffer ,element-type ,length ,@options)))
     (unwind-protect (progn ,@body)
       (free-native-buffer ,var))))

(defstruct (native-arena (:constructor make-native-arena ()))
  (buffers '())
  (active-p t :type boolean))

(defun arena-alloc (arena element-type length &rest options)
  "Allocates a buffer owned by ARENA. All arena buffers are released together."
  (unless (native-arena-active-p arena)
    (error 'native-memory-error :buffer nil :reason "native arena is no longer active"))
  (let ((buffer (apply #'make-native-buffer element-type length options)))
    (push buffer (native-arena-buffers arena))
    buffer))

(defun free-native-arena (arena)
  "Releases every allocation in ARENA. Idempotent."
  (when (native-arena-active-p arena)
    (dolist (buffer (native-arena-buffers arena)) (free-native-buffer buffer))
    (setf (native-arena-buffers arena) nil
          (native-arena-active-p arena) nil))
  arena)

(defmacro with-native-arena ((var) &body body)
  `(let ((,var (make-native-arena)))
     (unwind-protect (progn ,@body)
       (free-native-arena ,var))))

(defmacro with-stack-allocation (bindings &body body)
  "Nests CFFI:WITH-FOREIGN-OBJECT for temporary foreign allocations."
  (labels ((expand (remaining)
             (if (endp remaining)
                 `(progn ,@body)
                 (destructuring-bind (var type &optional (count 1)) (first remaining)
                   `(with-foreign-object (,var ,type ,count)
                      ,(expand (rest remaining)))))))
    (expand bindings)))

(defmacro with-foreign-array ((pointer type sequence) &body body)
  "Creates a temporary native array populated from SEQUENCE."
  (let ((seq (gensym "SEQUENCE")) (len (gensym "LENGTH")))
    `(let* ((,seq ,sequence) (,len (length ,seq)))
       (with-foreign-object (,pointer ,type (max 1 ,len))
         (loop for value across (coerce ,seq 'vector) for index from 0
               do (setf (mem-aref ,pointer ,type index) value))
         ,@body))))

(defun foreign-array-from-sequence (type sequence)
  "Returns an owned NATIVE-BUFFER populated with SEQUENCE."
  (let ((buffer (make-native-buffer type (length sequence))))
    (loop for value across (coerce sequence 'vector) for index from 0
          do (setf (buffer-ref buffer index) value))
    buffer))

(defun copy-foreign-array-to-list (pointer type count)
  (loop for index below count collect (mem-aref pointer type index)))

(defun make-pointer-buffer (length &rest options)
  "Allocates an address-sized buffer."
  (apply #'make-native-buffer :pointer length options))

(defun make-byte-buffer (length &rest options)
  (apply #'make-native-buffer :unsigned-char length options))
(defun make-short-buffer (length &rest options)
  (apply #'make-native-buffer :short length options))
(defun make-int-buffer (length &rest options)
  (apply #'make-native-buffer :int length options))
(defun make-long-buffer (length &rest options)
  (apply #'make-native-buffer :int64 length options))
(defun make-float-buffer (length &rest options)
  (apply #'make-native-buffer :float length options))
(defun make-double-buffer (length &rest options)
  (apply #'make-native-buffer :double length options))

(defun mem-alloc (element-type length &rest options)
  "LWJGL-style alias for MAKE-NATIVE-BUFFER."
  (apply #'make-native-buffer element-type length options))

(defun mem-calloc (element-type length &rest options)
  "Allocates a zero-filled native buffer."
  (apply #'make-native-buffer element-type length
         :initial-element (%native-zero element-type) options))

(defun mem-free (buffer) (free-native-buffer buffer))

(defun mem-address (buffer &optional (position (native-buffer-position buffer)))
  "Returns the native address at POSITION."
  (%check-buffer-live buffer)
  (unless (<= 0 position (native-buffer-limit buffer))
    (%memory-error buffer "address position ~D is outside the buffer limit" position))
  (pointer-address
   (inc-pointer (native-buffer-pointer buffer)
                (* position (native-buffer-element-size buffer)))))

(defun mem-utf8 (string &key arena (null-terminated t))
  (string-to-utf8-buffer string :arena arena :null-terminated null-terminated))

(defun string-to-utf8-buffer (string &key arena null-terminated)
  "Encodes STRING as UTF-8 in an owned or arena-backed byte buffer."
  (cffi:with-foreign-string ((source payload) string :encoding :utf-8)
    (let* ((length (if null-terminated payload (max 0 (1- payload))))
           (buffer (if arena
                       (arena-alloc arena :unsigned-char length)
                       (make-native-buffer :unsigned-char length))))
      (dotimes (index length buffer)
        (setf (buffer-ref buffer index)
              (cffi:mem-aref source :unsigned-char index))))))

(defun utf8-buffer-to-string (buffer &key (start (native-buffer-position buffer)) count)
  "Decodes UTF-8 from BUFFER without changing its cursor."
  (%check-buffer-live buffer)
  (let ((length (or count (- (native-buffer-limit buffer) start))))
    (unless (<= 0 start (+ start length) (native-buffer-limit buffer))
      (%memory-error buffer "invalid UTF-8 range"))
    (cffi:foreign-string-to-lisp
     (inc-pointer (native-buffer-pointer buffer) start)
     :count length :encoding :utf-8)))

;;; Dynamically scoped, thread-local-by-binding bump allocator.
(defstruct (memory-stack (:constructor %make-memory-stack))
  backing
  (offset 0 :type (integer 0 *))
  (frames '())
  (active-p t :type boolean))

(defvar *memory-stack* nil)

(defun make-memory-stack (&key (size (* 64 1024)))
  (%make-memory-stack :backing (make-native-buffer :unsigned-char size :alignment 16)))

(defun free-memory-stack (stack)
  (when (memory-stack-active-p stack)
    (free-native-buffer (memory-stack-backing stack))
    (setf (memory-stack-frames stack) nil
          (memory-stack-offset stack) 0
          (memory-stack-active-p stack) nil))
  stack)

(defun current-memory-stack ()
  (or *memory-stack* (error "No active memory stack; use WITH-MEMORY-STACK.")))

(defun stack-push (&optional (stack (current-memory-stack)))
  (unless (memory-stack-active-p stack)
    (error "Memory stack is no longer active."))
  (push (memory-stack-offset stack) (memory-stack-frames stack))
  stack)

(defun stack-pop (&optional (stack (current-memory-stack)))
  (unless (memory-stack-frames stack)
    (error "Memory stack frame underflow."))
  (setf (memory-stack-offset stack) (pop (memory-stack-frames stack)))
  stack)

(defun %align-up (value alignment)
  (+ value (mod (- alignment (mod value alignment)) alignment)))

(defun stack-malloc (element-type length &key alignment (stack (current-memory-stack)))
  "Bump-allocates a borrowed typed buffer from STACK."
  (let* ((element-size (foreign-type-size element-type))
         (actual-alignment (or alignment (%natural-alignment element-size)))
         (offset (%align-up (memory-stack-offset stack) actual-alignment))
         (bytes (* element-size length))
         (end (+ offset bytes))
         (backing (memory-stack-backing stack)))
    (unless (<= end (native-buffer-capacity-bytes backing))
      (error "Memory stack overflow: requested ~D bytes with ~D remaining."
             bytes (- (native-buffer-capacity-bytes backing) offset)))
    (setf (memory-stack-offset stack) end)
    (let ((buffer (wrap-native-buffer
                   (inc-pointer (native-buffer-pointer backing) offset)
                   element-type length :parent backing)))
      (setf (native-buffer-alignment buffer) actual-alignment)
      buffer)))

(defun stack-calloc (element-type length &key alignment (stack (current-memory-stack)))
  (fill-native-buffer
   (stack-malloc element-type length :alignment alignment :stack stack)
   (%native-zero element-type)))

(defmacro with-memory-stack ((var &key (size '(* 64 1024))) &body body)
  "Creates/reuses a dynamically scoped memory stack frame for BODY."
  (let ((owned (gensym "OWNED")) (stack (gensym "STACK")))
    `(let* ((,owned (null *memory-stack*))
            (,stack (or *memory-stack* (make-memory-stack :size ,size)))
            (*memory-stack* ,stack)
            (,var ,stack))
       (stack-push ,stack)
       (unwind-protect (locally ,@body)
         (stack-pop ,stack)
         (when ,owned (free-memory-stack ,stack))))))
