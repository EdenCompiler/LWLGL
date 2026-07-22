(in-package #:lwlgl.examples)

(defun audio-tone (&key (frequency 440.0d0) (duration 1.0d0))
  "Plays a mono sine wave through the canonical OpenAL 1.1 package."
  (lwlgl.openal.al11:al-with-openal ()
    (let ((samples (lwlgl.openal.al11:al-make-sine-wave
                    :frequency frequency :duration duration)))
      (multiple-value-bind (source buffer)
          (lwlgl.openal.al11:al-play-pcm16 samples 44100)
        (unwind-protect (lwlgl.openal.al11:al-wait-source source)
          (lwlgl.openal.al11:al-delete-source source)
          (lwlgl.openal.al11:al-delete-buffer buffer))))))
