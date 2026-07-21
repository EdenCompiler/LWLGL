(in-package #:lwlgl.util)

(defstruct (timer (:constructor %make-timer))
  id
  callback
  (remaining 0.0d0 :type double-float)
  (interval 0.0d0 :type double-float)
  (repeating-p nil :type boolean)
  (paused-p nil :type boolean)
  (cancelled-p nil :type boolean)
  (fire-count 0 :type (integer 0 *)))

(defstruct (timer-queue (:constructor %make-timer-queue))
  (timers '())
  (next-id 1 :type (integer 1 *))
  (time-scale 1.0d0 :type double-float)
  (paused-p nil :type boolean)
  (max-catch-up 8 :type (integer 1 *)))

(defun make-timer-queue (&key (time-scale 1.0d0) (max-catch-up 8))
  (when (minusp time-scale) (error "Timer queue time scale cannot be negative."))
  (when (< max-catch-up 1) (error "MAX-CATCH-UP must be at least 1."))
  (%make-timer-queue :time-scale (coerce time-scale 'double-float)
                     :max-catch-up max-catch-up))

(defun schedule-timer (queue delay callback &key repeat interval)
  "Schedules CALLBACK after DELAY seconds and returns a numeric timer id.
When REPEAT is true, INTERVAL defaults to DELAY and must be positive."
  (check-type callback function)
  (when (minusp delay) (error "Timer delay cannot be negative."))
  (let* ((repeat-interval (if repeat (or interval delay) 0.0d0))
         (id (timer-queue-next-id queue)))
    (when (and repeat (<= repeat-interval 0))
      (error "Repeating timers require a positive interval."))
    (incf (timer-queue-next-id queue))
    (push (%make-timer :id id
                       :callback callback
                       :remaining (coerce delay 'double-float)
                       :interval (coerce repeat-interval 'double-float)
                       :repeating-p (not (null repeat)))
          (timer-queue-timers queue))
    id))

(defun schedule-repeating-timer (queue interval callback &key (delay interval))
  (schedule-timer queue delay callback :repeat t :interval interval))

(defun %find-timer (queue id)
  (find id (timer-queue-timers queue) :key #'timer-id :test #'eql))

(defun timer-active-p (queue id)
  (let ((timer (%find-timer queue id)))
    (and timer (not (timer-cancelled-p timer)))))

(defun cancel-timer (queue id)
  (let ((timer (%find-timer queue id)))
    (when timer (setf (timer-cancelled-p timer) t)))
  queue)

(defun pause-timer (queue id)
  (let ((timer (%find-timer queue id)))
    (when timer (setf (timer-paused-p timer) t)))
  queue)

(defun resume-timer (queue id)
  (let ((timer (%find-timer queue id)))
    (when timer (setf (timer-paused-p timer) nil)))
  queue)

(defun clear-timers (queue)
  (setf (timer-queue-timers queue) '())
  queue)

(defun advance-timers (queue delta)
  "Advances QUEUE by DELTA seconds and returns the number of callbacks fired.
Callbacks are zero-argument functions. Repeating timers cap catch-up callbacks per update."
  (when (minusp delta) (error "Timer delta cannot be negative."))
  (when (timer-queue-paused-p queue) (return-from advance-timers 0))
  (let ((scaled-delta (* (coerce delta 'double-float) (timer-queue-time-scale queue)))
        (fired 0))
    (dolist (timer (copy-list (timer-queue-timers queue)))
      (unless (or (timer-cancelled-p timer) (timer-paused-p timer))
        (decf (timer-remaining timer) scaled-delta)
        (let ((catch-up 0))
          (loop while (and (not (timer-cancelled-p timer))
                           (<= (timer-remaining timer) 0.0d0)
                           (< catch-up (timer-queue-max-catch-up queue)))
                do (incf catch-up)
                   (incf fired)
                   (incf (timer-fire-count timer))
                   (funcall (timer-callback timer))
                   (if (timer-repeating-p timer)
                       (incf (timer-remaining timer) (timer-interval timer))
                       (setf (timer-cancelled-p timer) t)))
        (when (and (timer-repeating-p timer)
                   (not (timer-cancelled-p timer))
                   (<= (timer-remaining timer) 0.0d0))
          (setf (timer-remaining timer)
                (mod (timer-remaining timer) (timer-interval timer)))
          (when (<= (timer-remaining timer) 0.0d0)
            (incf (timer-remaining timer) (timer-interval timer)))))))
    (setf (timer-queue-timers queue)
          (delete-if #'timer-cancelled-p (timer-queue-timers queue)))
    fired))
