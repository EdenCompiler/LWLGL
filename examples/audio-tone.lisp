(in-package #:lwlgl.examples)

(defun audio-tone (&key (frequency 440.0d0) (duration 1.0d0))
  "Toca uma senoide mono usando OpenAL."
  (lwlgl.openal:with-openal ()
    (let ((samples (lwlgl.openal:make-sine-wave :frequency frequency :duration duration)))
      (multiple-value-bind (source buffer) (lwlgl.openal:play-pcm16 samples 44100)
        (unwind-protect (lwlgl.openal:wait-source source)
          (lwlgl.openal:delete-source source)
          (lwlgl.openal:delete-buffer buffer))))))
