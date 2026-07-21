(in-package #:lwlgl.util)

(defstruct (profile-stat (:constructor %make-profile-stat (name)))
  name
  (count 0 :type (integer 0 *))
  (total 0.0d0 :type double-float)
  (last 0.0d0 :type double-float)
  (minimum most-positive-double-float :type double-float)
  (maximum 0.0d0 :type double-float))

(defun profile-stat-average (stat)
  (if (zerop (profile-stat-count stat)) 0.0d0
      (/ (profile-stat-total stat) (profile-stat-count stat))))

(defstruct (profiler (:constructor %make-profiler (stats)))
  stats)

(defun make-profiler (&key (test #'equal))
  (%make-profiler (make-hash-table :test test)))

(defun profiler-record (profiler name seconds)
  (let* ((table (profiler-stats profiler))
         (sample (coerce seconds 'double-float))
         (stat (or (gethash name table)
                   (setf (gethash name table) (%make-profile-stat name)))))
    (incf (profile-stat-count stat))
    (incf (profile-stat-total stat) sample)
    (setf (profile-stat-last stat) sample
          (profile-stat-minimum stat) (min (profile-stat-minimum stat) sample)
          (profile-stat-maximum stat) (max (profile-stat-maximum stat) sample))
    stat))

(defun profiler-stat (profiler name) (gethash name (profiler-stats profiler)))

(defun reset-profiler (profiler)
  (clrhash (profiler-stats profiler))
  profiler)

(defun profiler-report (profiler &key (sort-by :total) (descending t))
  "Returns profile stats sorted by :TOTAL, :AVERAGE, :MAXIMUM, :LAST, :COUNT or :NAME."
  (let ((items (loop for stat being the hash-values of (profiler-stats profiler) collect stat)))
    (labels ((value (stat)
               (ecase sort-by
                 (:total (profile-stat-total stat))
                 (:average (profile-stat-average stat))
                 (:maximum (profile-stat-maximum stat))
                 (:last (profile-stat-last stat))
                 (:count (profile-stat-count stat))
                 (:name (princ-to-string (profile-stat-name stat))))))
      (sort items (if (eq sort-by :name)
                      (if descending #'string> #'string<)
                      (if descending #'> #'<))
            :key #'value))))

(defmacro with-profiled-section ((profiler name) &body body)
  "Times BODY and records the elapsed wall/process time under NAME, even when BODY exits non-locally."
  (let ((start (gensym "START")))
    `(let ((,start (monotonic-seconds)))
       (unwind-protect
            (progn ,@body)
         (profiler-record ,profiler ,name (- (monotonic-seconds) ,start))))))
