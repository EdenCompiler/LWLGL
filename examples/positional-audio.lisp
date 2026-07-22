(in-package #:lwlgl.examples)

(defun positional-audio (&key (duration 2.0d0) (frequency 523.25d0))
  "Moves a mono OpenAL source from left to right while it plays."
  (check-type duration (real 0 *))
  (lwlgl.openal.al11:al-with-openal ()
    (lwlgl.openal.al11:al-listener-3f
     lwlgl.openal.al11:+al-position+ 0.0 0.0 0.0)
    (lwlgl.openal.al11:al-set-listener-orientation 0.0 0.0 -1.0 0.0 1.0 0.0)
    (let ((samples
            (lwlgl.openal.al11:al-make-sine-wave
             :frequency frequency :duration duration :amplitude 0.18d0)))
      (multiple-value-bind (source buffer)
          (lwlgl.openal.al11:al-play-pcm16 samples 44100 :gain-value 0.8)
        (unwind-protect
             (let ((steps 60))
               (dotimes (step steps)
                 (let ((x (- (* 6.0 (/ step (1- steps))) 3.0)))
                   (lwlgl.openal.al11:al-source-3f
                    source lwlgl.openal.al11:+al-position+ x 0.0 -2.0))
                 (sleep (/ duration steps)))
               (lwlgl.openal.al11:al-wait-source source))
          (lwlgl.openal.al11:al-delete-source source)
          (lwlgl.openal.al11:al-delete-buffer buffer))))))
