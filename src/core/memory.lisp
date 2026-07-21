(in-package #:lwlgl.core)

(defstruct (native-buffer (:constructor %make-native-buffer))
  pointer
  length
  element-type
  (owned-p t))

(defun make-native-buffer (element-type length &key (initial-element nil initial-element-p))
  "Aloca memória nativa contígua para LENGTH elementos CFFI."
  (check-type length (integer 0 *))
  (let* ((count (max 1 length))
         (pointer (foreign-alloc element-type :count count)))
    (let ((buffer (%make-native-buffer :pointer pointer :length length
                                       :element-type element-type :owned-p t)))
      (when initial-element-p
        (dotimes (index length)
          (setf (mem-aref pointer element-type index) initial-element)))
      buffer)))

(defun free-native-buffer (buffer)
  "Libera BUFFER se ele for dono da alocação. Operação idempotente."
  (when (and buffer (native-buffer-owned-p buffer)
             (native-buffer-pointer buffer)
             (not (null-pointer-p (native-buffer-pointer buffer))))
    (foreign-free (native-buffer-pointer buffer))
    (setf (native-buffer-pointer buffer) (null-pointer)
          (native-buffer-owned-p buffer) nil))
  buffer)

(defun %check-buffer-index (buffer index)
  (unless (and (integerp index) (<= 0 index) (< index (native-buffer-length buffer)))
    (error "Índice ~A fora do intervalo [0, ~A)." index (native-buffer-length buffer))))

(defun buffer-ref (buffer index)
  (%check-buffer-index buffer index)
  (mem-aref (native-buffer-pointer buffer) (native-buffer-element-type buffer) index))

(defun buffer-set (buffer index value)
  (%check-buffer-index buffer index)
  (setf (mem-aref (native-buffer-pointer buffer) (native-buffer-element-type buffer) index)
        value))

(defsetf buffer-ref (buffer index) (value)
  `(buffer-set ,buffer ,index ,value))

(defmacro with-native-buffer ((var element-type length &rest options) &body body)
  `(let ((,var (make-native-buffer ,element-type ,length ,@options)))
     (unwind-protect
          (progn ,@body)
       (free-native-buffer ,var))))

(defmacro with-stack-allocation (bindings &body body)
  "Aninha CFFI:WITH-FOREIGN-OBJECT para um pequeno conjunto de alocações temporárias.
Cada binding tem a forma (VAR TIPO &optional CONTAGEM)."
  (labels ((expand (remaining)
             (if (endp remaining)
                 `(progn ,@body)
                 (destructuring-bind (var type &optional (count 1)) (first remaining)
                   `(with-foreign-object (,var ,type ,count)
                      ,(expand (rest remaining)))))))
    (expand bindings)))

(defmacro with-foreign-array ((pointer type sequence) &body body)
  "Cria um array nativo temporário preenchido a partir de SEQUENCE."
  (let ((seq (gensym "SEQUENCE"))
        (len (gensym "LENGTH")))
    `(let* ((,seq ,sequence)
            (,len (length ,seq)))
       (with-foreign-object (,pointer ,type (max 1 ,len))
         (loop for value across (coerce ,seq 'vector)
               for index from 0
               do (setf (mem-aref ,pointer ,type index) value))
         ,@body))))

(defun foreign-array-from-sequence (type sequence)
  "Retorna um NATIVE-BUFFER proprietário preenchido com SEQUENCE."
  (let ((buffer (make-native-buffer type (length sequence))))
    (loop for value across (coerce sequence 'vector)
          for index from 0
          do (setf (buffer-ref buffer index) value))
    buffer))

(defun copy-foreign-array-to-list (pointer type count)
  (loop for index below count collect (mem-aref pointer type index)))
