(in-package #:lwlgl.glfw)

(cffi:defcstruct glfw-video-mode
  (width :int) (height :int)
  (red-bits :int) (green-bits :int) (blue-bits :int)
  (refresh-rate :int))

(cffi:defcstruct glfw-gamepad-state
  (buttons :unsigned-char :count 15)
  (axes :float :count 6))

(cffi:defcfun ("glfwGetMonitors" %glfw-get-monitors) :pointer (count :pointer))
(cffi:defcfun ("glfwGetPrimaryMonitor" %glfw-get-primary-monitor) :pointer)
(cffi:defcfun ("glfwGetMonitorName" %glfw-get-monitor-name) :pointer (monitor :pointer))
(cffi:defcfun ("glfwGetMonitorPos" %glfw-get-monitor-pos) :void (monitor :pointer) (x :pointer) (y :pointer))
(cffi:defcfun ("glfwGetMonitorContentScale" %glfw-get-monitor-content-scale) :void
  (monitor :pointer) (xscale :pointer) (yscale :pointer))
(cffi:defcfun ("glfwGetMonitorPhysicalSize" %glfw-get-monitor-physical-size) :void
  (monitor :pointer) (width-mm :pointer) (height-mm :pointer))
(cffi:defcfun ("glfwGetVideoMode" %glfw-get-video-mode) :pointer (monitor :pointer))
(cffi:defcfun ("glfwGetVideoModes" %glfw-get-video-modes) :pointer (monitor :pointer) (count :pointer))

(cffi:defcfun ("glfwJoystickPresent" %glfw-joystick-present) :int (jid :int))
(cffi:defcfun ("glfwGetJoystickName" %glfw-get-joystick-name) :pointer (jid :int))
(cffi:defcfun ("glfwGetJoystickGUID" %glfw-get-joystick-guid) :pointer (jid :int))
(cffi:defcfun ("glfwGetJoystickAxes" %glfw-get-joystick-axes) :pointer (jid :int) (count :pointer))
(cffi:defcfun ("glfwGetJoystickButtons" %glfw-get-joystick-buttons) :pointer (jid :int) (count :pointer))
(cffi:defcfun ("glfwGetJoystickHats" %glfw-get-joystick-hats) :pointer (jid :int) (count :pointer))
(cffi:defcfun ("glfwJoystickIsGamepad" %glfw-joystick-is-gamepad) :int (jid :int))
(cffi:defcfun ("glfwGetGamepadName" %glfw-get-gamepad-name) :pointer (jid :int))
(cffi:defcfun ("glfwGetGamepadState" %glfw-get-gamepad-state) :int (jid :int) (state :pointer))

(defconstant joystick-1 0)
(defconstant joystick-last 15)

(defconstant gamepad-button-a 0)
(defconstant gamepad-button-b 1)
(defconstant gamepad-button-x 2)
(defconstant gamepad-button-y 3)
(defconstant gamepad-button-left-bumper 4)
(defconstant gamepad-button-right-bumper 5)
(defconstant gamepad-button-back 6)
(defconstant gamepad-button-start 7)
(defconstant gamepad-button-guide 8)
(defconstant gamepad-button-left-thumb 9)
(defconstant gamepad-button-right-thumb 10)
(defconstant gamepad-button-dpad-up 11)
(defconstant gamepad-button-dpad-right 12)
(defconstant gamepad-button-dpad-down 13)
(defconstant gamepad-button-dpad-left 14)

(defconstant gamepad-axis-left-x 0)
(defconstant gamepad-axis-left-y 1)
(defconstant gamepad-axis-right-x 2)
(defconstant gamepad-axis-right-y 3)
(defconstant gamepad-axis-left-trigger 4)
(defconstant gamepad-axis-right-trigger 5)

(defclass monitor ()
  ((handle :initarg :handle :reader monitor-handle)
   (name :initarg :name :reader monitor-name)))

(defstruct video-mode
  (width 0 :type integer)
  (height 0 :type integer)
  (red-bits 0 :type integer)
  (green-bits 0 :type integer)
  (blue-bits 0 :type integer)
  (refresh-rate 0 :type integer))

(defun %pointer-string (pointer)
  (unless (or (null pointer) (cffi:null-pointer-p pointer))
    (cffi:foreign-string-to-lisp pointer)))

(defun %make-monitor (pointer)
  (unless (cffi:null-pointer-p pointer)
    (make-instance 'monitor :handle pointer :name (%pointer-string (%glfw-get-monitor-name pointer)))))

(defun get-monitors ()
  (%ensure-glfw)
  (cffi:with-foreign-object (count :int)
    (let ((array (%glfw-get-monitors count)))
      (if (cffi:null-pointer-p array)
          '()
          (loop for i below (cffi:mem-ref count :int)
                for pointer = (cffi:mem-aref array :pointer i)
                collect (%make-monitor pointer))))))

(defun primary-monitor ()
  (%ensure-glfw)
  (%make-monitor (%glfw-get-primary-monitor)))

(defun monitor-position (monitor)
  (cffi:with-foreign-objects ((x :int) (y :int))
    (%glfw-get-monitor-pos (monitor-handle monitor) x y)
    (values (cffi:mem-ref x :int) (cffi:mem-ref y :int))))

(defun monitor-content-scale (monitor)
  (cffi:with-foreign-objects ((x :float) (y :float))
    (%glfw-get-monitor-content-scale (monitor-handle monitor) x y)
    (values (cffi:mem-ref x :float) (cffi:mem-ref y :float))))

(defun monitor-physical-size (monitor)
  (cffi:with-foreign-objects ((width :int) (height :int))
    (%glfw-get-monitor-physical-size (monitor-handle monitor) width height)
    (values (cffi:mem-ref width :int) (cffi:mem-ref height :int))))

(defun %video-mode-from-pointer (pointer &optional (index 0))
  (let ((mode (cffi:mem-aptr pointer '(:struct glfw-video-mode) index)))
    (make-video-mode
     :width (cffi:foreign-slot-value mode '(:struct glfw-video-mode) 'width)
     :height (cffi:foreign-slot-value mode '(:struct glfw-video-mode) 'height)
     :red-bits (cffi:foreign-slot-value mode '(:struct glfw-video-mode) 'red-bits)
     :green-bits (cffi:foreign-slot-value mode '(:struct glfw-video-mode) 'green-bits)
     :blue-bits (cffi:foreign-slot-value mode '(:struct glfw-video-mode) 'blue-bits)
     :refresh-rate (cffi:foreign-slot-value mode '(:struct glfw-video-mode) 'refresh-rate))))

(defun monitor-video-mode (monitor)
  (let ((pointer (%glfw-get-video-mode (monitor-handle monitor))))
    (unless (cffi:null-pointer-p pointer)
      (%video-mode-from-pointer pointer))))

(defun monitor-video-modes (monitor)
  (cffi:with-foreign-object (count :int)
    (let ((pointer (%glfw-get-video-modes (monitor-handle monitor) count)))
      (if (cffi:null-pointer-p pointer)
          '()
          (loop for i below (cffi:mem-ref count :int)
                collect (%video-mode-from-pointer pointer i))))))

(defun joystick-present-p (jid)
  (not (zerop (%glfw-joystick-present jid))))

(defun joystick-name (jid) (%pointer-string (%glfw-get-joystick-name jid)))
(defun joystick-guid (jid) (%pointer-string (%glfw-get-joystick-guid jid)))

(defun %native-vector (pointer count type)
  (if (cffi:null-pointer-p pointer)
      #()
      (let ((out (make-array count)))
        (dotimes (i count out)
          (setf (aref out i) (cffi:mem-aref pointer type i))))))

(defun joystick-axes (jid)
  (cffi:with-foreign-object (count :int)
    (let ((pointer (%glfw-get-joystick-axes jid count)))
      (%native-vector pointer (cffi:mem-ref count :int) :float))))

(defun joystick-buttons (jid)
  (cffi:with-foreign-object (count :int)
    (let ((pointer (%glfw-get-joystick-buttons jid count)))
      (%native-vector pointer (cffi:mem-ref count :int) :unsigned-char))))

(defun joystick-hats (jid)
  (cffi:with-foreign-object (count :int)
    (let ((pointer (%glfw-get-joystick-hats jid count)))
      (%native-vector pointer (cffi:mem-ref count :int) :unsigned-char))))

(defun joystick-is-gamepad-p (jid)
  (not (zerop (%glfw-joystick-is-gamepad jid))))

(defun gamepad-name (jid)
  (%pointer-string (%glfw-get-gamepad-name jid)))

(defun gamepad-state (jid)
  "Returns two values: a 15-element button vector and a 6-element axis vector, or NIL if unavailable."
  (cffi:with-foreign-object (state '(:struct glfw-gamepad-state))
    (if (zerop (%glfw-get-gamepad-state jid state))
        (values nil nil)
        (let ((buttons (make-array 15 :element-type '(unsigned-byte 8)))
              (axes (make-array 6 :element-type 'single-float))
              (button-pointer (cffi:foreign-slot-pointer state '(:struct glfw-gamepad-state) 'buttons))
              (axis-pointer (cffi:foreign-slot-pointer state '(:struct glfw-gamepad-state) 'axes)))
          (dotimes (i 15) (setf (aref buttons i) (cffi:mem-aref button-pointer :unsigned-char i)))
          (dotimes (i 6) (setf (aref axes i) (cffi:mem-aref axis-pointer :float i)))
          (values buttons axes)))))
