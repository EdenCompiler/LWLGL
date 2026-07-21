(in-package #:lwlgl.util)

(defun monotonic-seconds ()
  "Returns a monotonic-ish process clock in seconds using Common Lisp internal real time."
  (/ (get-internal-real-time) (float internal-time-units-per-second 1.0d0)))

(defun clamp (value minimum maximum)
  (max minimum (min maximum value)))

(defun lerp (a b amount)
  (+ a (* (- b a) amount)))

(defun inverse-lerp (a b value)
  (if (= a b) 0.0 (/ (- value a) (- b a))))

(defun smoothstep (edge0 edge1 value)
  (let ((x (clamp (inverse-lerp edge0 edge1 value) 0.0 1.0)))
    (* x x (- 3.0 (* 2.0 x)))))

(defstruct (frame-clock (:constructor %make-frame-clock))
  (start-time 0.0d0 :type double-float)
  (last-time 0.0d0 :type double-float)
  (delta 0.0d0 :type double-float)
  (elapsed 0.0d0 :type double-float)
  (frame-count 0 :type (integer 0 *))
  (fps 0.0d0 :type double-float)
  (fps-window-start 0.0d0 :type double-float)
  (fps-window-frames 0 :type (integer 0 *)))

(defun make-frame-clock ()
  (let ((now (monotonic-seconds)))
    (%make-frame-clock :start-time now :last-time now :fps-window-start now)))

(defun reset-frame-clock (clock)
  (let ((now (monotonic-seconds)))
    (setf (frame-clock-start-time clock) now
          (frame-clock-last-time clock) now
          (frame-clock-delta clock) 0.0d0
          (frame-clock-elapsed clock) 0.0d0
          (frame-clock-frame-count clock) 0
          (frame-clock-fps clock) 0.0d0
          (frame-clock-fps-window-start clock) now
          (frame-clock-fps-window-frames clock) 0)
    clock))

(defun tick-frame-clock (clock &key (max-delta 0.25d0))
  "Advances CLOCK. Returns DELTA, ELAPSED and the latest one-second-window FPS estimate."
  (let* ((now (monotonic-seconds))
         (raw-delta (- now (frame-clock-last-time clock)))
         (delta (max 0.0d0 (min raw-delta max-delta))))
    (setf (frame-clock-last-time clock) now
          (frame-clock-delta clock) delta
          (frame-clock-elapsed clock) (- now (frame-clock-start-time clock)))
    (incf (frame-clock-frame-count clock))
    (incf (frame-clock-fps-window-frames clock))
    (let ((window (- now (frame-clock-fps-window-start clock))))
      (when (>= window 1.0d0)
        (setf (frame-clock-fps clock) (/ (frame-clock-fps-window-frames clock) window)
              (frame-clock-fps-window-start clock) now
              (frame-clock-fps-window-frames clock) 0)))
    (values delta (frame-clock-elapsed clock) (frame-clock-fps clock))))

(defstruct (fixed-step (:constructor %make-fixed-step))
  (dt (/ 1.0d0 60.0d0) :type double-float)
  (accumulator 0.0d0 :type double-float)
  (max-steps 8 :type (integer 1 *)))

(defun make-fixed-step (&key (hz 60.0d0) dt (max-steps 8))
  (let ((step (or dt (/ 1.0d0 hz))))
    (when (<= step 0) (error "Fixed timestep must be positive."))
    (%make-fixed-step :dt (coerce step 'double-float) :max-steps max-steps)))

(defun reset-fixed-step (fixed-step)
  (setf (fixed-step-accumulator fixed-step) 0.0d0)
  fixed-step)

(defun advance-fixed-step (fixed-step frame-delta update-function)
  "Runs UPDATE-FUNCTION with the fixed dt zero or more times.
Returns interpolation alpha and number of simulation steps. A step cap avoids a spiral of death."
  (incf (fixed-step-accumulator fixed-step) (coerce frame-delta 'double-float))
  (let ((steps 0)
        (dt (fixed-step-dt fixed-step)))
    (loop while (and (>= (fixed-step-accumulator fixed-step) dt)
                     (< steps (fixed-step-max-steps fixed-step)))
          do (funcall update-function dt)
             (decf (fixed-step-accumulator fixed-step) dt)
             (incf steps))
    (when (>= (fixed-step-accumulator fixed-step) dt)
      ;; Drop excess backlog after the cap; deterministic simulation remains bounded.
      (setf (fixed-step-accumulator fixed-step)
            (mod (fixed-step-accumulator fixed-step) dt)))
    (values (/ (fixed-step-accumulator fixed-step) dt) steps)))
