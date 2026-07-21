(in-package #:lwlgl.openal)

(defmacro with-openal ((&key device context device-name) &body body)
  "Opens an OpenAL device/context and guarantees cleanup in a safe order."
  (let ((device-var (or device (gensym "DEVICE")))
        (context-var (or context (gensym "CONTEXT"))))
    `(let* ((,device-var (open-device ,device-name))
            (,context-var (and (not (cffi:null-pointer-p ,device-var))
                               (create-context ,device-var))))
       (when (or (cffi:null-pointer-p ,device-var)
                 (cffi:null-pointer-p ,context-var))
         (error "Could not create OpenAL device/context."))
       (unwind-protect
            (progn
              (unless (make-context-current ,context-var)
                (error "Could not activate the OpenAL context."))
              ,@body)
         (make-context-current (cffi:null-pointer))
         (destroy-context ,context-var)
         (close-device ,device-var)))))

(defun make-sine-wave (&key (frequency 440.0d0) (duration 1.0d0) (sample-rate 44100) (amplitude 0.25d0))
  "Generates a mono signed 16-bit sine wave vector."
  (let* ((count (round (* duration sample-rate)))
         (samples (make-array count :element-type '(signed-byte 16)))
         (scale (* amplitude 32767.0d0)))
    (dotimes (index count samples)
      (setf (aref samples index)
            (round (* scale (sin (* 2.0d0 pi frequency (/ index sample-rate)))))))))

(defun play-pcm16 (samples sample-rate &key (channels 1) (looping-p nil) (gain-value 1.0))
  "Creates a buffer/source and starts PCM16 playback. Returns SOURCE and BUFFER."
  (let ((buffer (gen-buffer))
        (source (gen-source))
        (format (ecase channels (1 format-mono16) (2 format-stereo16))))
    (cffi:with-foreign-object (data :short (length samples))
      (dotimes (index (length samples))
        (setf (cffi:mem-aref data :short index) (aref samples index)))
      (buffer-data buffer format data (* (length samples) 2) sample-rate))
    (source-i source buffer-binding buffer)
    (source-i source looping (if looping-p 1 0))
    (source-f source gain gain-value)
    (source-play source)
    (values source buffer)))

(defun wait-source (source &key (sleep-seconds 0.01))
  "Blocks until SOURCE leaves the PLAYING state."
  (loop while (= (get-source-i source source-state) playing)
        do (sleep sleep-seconds))
  source)

(defun set-listener-orientation (at-x at-y at-z up-x up-y up-z)
  "Sets the listener forward and up vectors."
  (let ((values (vector (coerce at-x 'single-float) (coerce at-y 'single-float) (coerce at-z 'single-float)
                        (coerce up-x 'single-float) (coerce up-y 'single-float) (coerce up-z 'single-float))))
    (lwlgl.core:with-foreign-array (pointer :float values)
      (listener-fv orientation pointer))))

(defun queue-pcm16 (source chunks sample-rate &key (channels 1))
  "Creates one OpenAL buffer per PCM16 chunk, queues them on SOURCE and returns the buffer vector."
  (let* ((format (ecase channels (1 format-mono16) (2 format-stereo16)))
         (buffers (make-array (length chunks) :element-type '(unsigned-byte 32))))
    (loop for chunk across (coerce chunks 'vector)
          for i from 0
          for buffer = (gen-buffer)
          do (setf (aref buffers i) buffer)
             (cffi:with-foreign-object (data :short (length chunk))
               (dotimes (j (length chunk))
                 (setf (cffi:mem-aref data :short j) (aref chunk j)))
               (buffer-data buffer format data (* (length chunk) 2) sample-rate)))
    (source-queue-buffers source buffers)
    buffers))

(defun unqueue-processed-buffers (source)
  "Unqueues and returns all buffers OpenAL reports as processed."
  (let ((count (get-source-i source buffers-processed)))
    (if (plusp count) (source-unqueue-buffers source count) #())))
