(in-package #:lwlgl.core)

(defstruct (native-buffer (:constructor %make-native-buffer) (:copier nil))
  pointer
  allocation-pointer
  (length 0 :type (integer 0 *))
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
