(in-package #:lwlgl.input)

(defstruct (input-state (:constructor %make-input-state))
  (keys-down (make-hash-table :test #'eql))
  (keys-pressed (make-hash-table :test #'eql))
  (keys-released (make-hash-table :test #'eql))
  (mouse-down (make-hash-table :test #'eql))
  (mouse-pressed (make-hash-table :test #'eql))
  (mouse-released (make-hash-table :test #'eql))
  (mouse-x 0.0d0 :type double-float)
  (mouse-y 0.0d0 :type double-float)
  (mouse-dx 0.0d0 :type double-float)
  (mouse-dy 0.0d0 :type double-float)
  (scroll-x 0.0d0 :type double-float)
  (scroll-y 0.0d0 :type double-float)
  (focused-p t :type boolean)
  (codepoints '())
  window
  key-handler mouse-handler cursor-handler scroll-handler char-handler focus-handler)

(defun make-input-state (&optional window)
  (let ((state (%make-input-state)))
    (if window (attach-input-state state window) state)))

(defun input-attached-p (state)
  (not (null (input-state-window state))))

(defun %set-flag (table key value)
  (if value (setf (gethash key table) t) (remhash key table)))

(defun attach-input-state (state window)
  "Attaches STATE to WINDOW using composable GLFW handlers. Detaches any prior window first."
  (when (input-state-window state)
    (detach-input-state state))
  (multiple-value-bind (x y) (lwlgl.glfw:cursor-position window)
    (setf (input-state-mouse-x state) x
          (input-state-mouse-y state) y))
  (let ((key-handler
          (lambda (w key scancode action mods)
            (declare (ignore w scancode mods))
            (case action
              (#.lwlgl.glfw:press
               (unless (gethash key (input-state-keys-down state))
                 (setf (gethash key (input-state-keys-pressed state)) t))
               (setf (gethash key (input-state-keys-down state)) t))
              (#.lwlgl.glfw:release
               (remhash key (input-state-keys-down state))
               (setf (gethash key (input-state-keys-released state)) t)))))
        (mouse-handler
          (lambda (w button action mods)
            (declare (ignore w mods))
            (case action
              (#.lwlgl.glfw:press
               (unless (gethash button (input-state-mouse-down state))
                 (setf (gethash button (input-state-mouse-pressed state)) t))
               (setf (gethash button (input-state-mouse-down state)) t))
              (#.lwlgl.glfw:release
               (remhash button (input-state-mouse-down state))
               (setf (gethash button (input-state-mouse-released state)) t)))))
        (cursor-handler
          (lambda (w x y)
            (declare (ignore w))
            (incf (input-state-mouse-dx state) (- x (input-state-mouse-x state)))
            (incf (input-state-mouse-dy state) (- y (input-state-mouse-y state)))
            (setf (input-state-mouse-x state) x (input-state-mouse-y state) y)))
        (scroll-handler
          (lambda (w x y)
            (declare (ignore w))
            (incf (input-state-scroll-x state) x)
            (incf (input-state-scroll-y state) y)))
        (char-handler
          (lambda (w codepoint)
            (declare (ignore w))
            (push codepoint (input-state-codepoints state))))
        (focus-handler
          (lambda (w focused)
            (declare (ignore w))
            (setf (input-state-focused-p state) focused)
            (unless focused
              (clrhash (input-state-keys-down state))
              (clrhash (input-state-mouse-down state))))))
    (setf (input-state-window state) window
          (input-state-key-handler state) key-handler
          (input-state-mouse-handler state) mouse-handler
          (input-state-cursor-handler state) cursor-handler
          (input-state-scroll-handler state) scroll-handler
          (input-state-char-handler state) char-handler
          (input-state-focus-handler state) focus-handler)
    (lwlgl.glfw:add-key-handler window key-handler)
    (lwlgl.glfw:add-mouse-button-handler window mouse-handler)
    (lwlgl.glfw:add-cursor-position-handler window cursor-handler)
    (lwlgl.glfw:add-scroll-handler window scroll-handler)
    (lwlgl.glfw:add-char-handler window char-handler)
    (lwlgl.glfw:add-focus-handler window focus-handler))
  state)

(defun detach-input-state (state)
  (let ((window (input-state-window state)))
    (when window
      (lwlgl.glfw:remove-key-handler window (input-state-key-handler state))
      (lwlgl.glfw:remove-mouse-button-handler window (input-state-mouse-handler state))
      (lwlgl.glfw:remove-cursor-position-handler window (input-state-cursor-handler state))
      (lwlgl.glfw:remove-scroll-handler window (input-state-scroll-handler state))
      (lwlgl.glfw:remove-char-handler window (input-state-char-handler state))
      (lwlgl.glfw:remove-focus-handler window (input-state-focus-handler state)))
    (setf (input-state-window state) nil
          (input-state-key-handler state) nil
          (input-state-mouse-handler state) nil
          (input-state-cursor-handler state) nil
          (input-state-scroll-handler state) nil
          (input-state-char-handler state) nil
          (input-state-focus-handler state) nil))
  state)

(defun begin-input-frame (state)
  "Clears one-frame transitions/deltas. Call before GLFW:POLL-EVENTS for event-driven frame input."
  (clrhash (input-state-keys-pressed state))
  (clrhash (input-state-keys-released state))
  (clrhash (input-state-mouse-pressed state))
  (clrhash (input-state-mouse-released state))
  (setf (input-state-mouse-dx state) 0.0d0
        (input-state-mouse-dy state) 0.0d0
        (input-state-scroll-x state) 0.0d0
        (input-state-scroll-y state) 0.0d0
        (input-state-codepoints state) '())
  state)

(defun key-down-p (state key) (not (null (gethash key (input-state-keys-down state)))))
(defun key-pressed-p (state key) (not (null (gethash key (input-state-keys-pressed state)))))
(defun key-released-p (state key) (not (null (gethash key (input-state-keys-released state)))))
(defun mouse-down-p (state button) (not (null (gethash button (input-state-mouse-down state)))))
(defun mouse-pressed-p (state button) (not (null (gethash button (input-state-mouse-pressed state)))))
(defun mouse-released-p (state button) (not (null (gethash button (input-state-mouse-released state)))))

(defun mouse-position (state)
  (values (input-state-mouse-x state) (input-state-mouse-y state)))

(defun mouse-delta (state)
  (values (input-state-mouse-dx state) (input-state-mouse-dy state)))

(defun scroll-delta (state)
  (values (input-state-scroll-x state) (input-state-scroll-y state)))

(defun input-focused-p (state) (input-state-focused-p state))

(defun text-input (state)
  (coerce (loop for codepoint in (nreverse (copy-list (input-state-codepoints state)))
                for character = (code-char codepoint)
                when character collect character)
          'string))

(defun consume-text-input (state)
  (prog1 (text-input state)
    (setf (input-state-codepoints state) '())))
