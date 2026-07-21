(in-package #:lwlgl.openal)

(lwlgl.core:register-native-module
 :openal
 (lwlgl.core:platform-library-names
  :windows '("OpenAL32.dll" "soft_oal.dll")
  :macos '("/System/Library/Frameworks/OpenAL.framework/OpenAL" "libopenal.dylib")
  :linux '("libopenal.so.1" "libopenal.so")))

(defconstant format-mono8 #x1100)
(defconstant format-mono16 #x1101)
(defconstant format-stereo8 #x1102)
(defconstant format-stereo16 #x1103)
(defconstant pitch #x1003)
(defconstant position #x1004)
(defconstant direction #x1005)
(defconstant velocity #x1006)
(defconstant looping #x1007)
(defconstant buffer-binding #x1009)
(defconstant gain #x100A)
(defconstant orientation #x100F)
(defconstant source-state #x1010)
(defconstant initial #x1011)
(defconstant playing #x1012)
(defconstant paused #x1013)
(defconstant stopped #x1014)
(defconstant buffers-queued #x1015)
(defconstant buffers-processed #x1016)
(defconstant source-relative #x0202)

(cffi:defcfun ("alcOpenDevice" %alc-open-device) :pointer (name :pointer))
(cffi:defcfun ("alcCloseDevice" %alc-close-device) :unsigned-char (device :pointer))
(cffi:defcfun ("alcCreateContext" %alc-create-context) :pointer (device :pointer) (attrs :pointer))
(cffi:defcfun ("alcDestroyContext" %alc-destroy-context) :void (context :pointer))
(cffi:defcfun ("alcMakeContextCurrent" %alc-make-context-current) :unsigned-char (context :pointer))
(cffi:defcfun ("alGenBuffers" %al-gen-buffers) :void (n :int) (buffers :pointer))
(cffi:defcfun ("alDeleteBuffers" %al-delete-buffers) :void (n :int) (buffers :pointer))
(cffi:defcfun ("alBufferData" %al-buffer-data) :void
  (buffer :unsigned-int) (format :int) (data :pointer) (size :int) (frequency :int))
(cffi:defcfun ("alGenSources" %al-gen-sources) :void (n :int) (sources :pointer))
(cffi:defcfun ("alDeleteSources" %al-delete-sources) :void (n :int) (sources :pointer))
(cffi:defcfun ("alSourcei" %al-source-i) :void (source :unsigned-int) (param :int) (value :int))
(cffi:defcfun ("alSourcef" %al-source-f) :void (source :unsigned-int) (param :int) (value :float))
(cffi:defcfun ("alSource3f" %al-source-3f) :void
  (source :unsigned-int) (param :int) (x :float) (y :float) (z :float))
(cffi:defcfun ("alSourcePlay" %al-source-play) :void (source :unsigned-int))
(cffi:defcfun ("alSourcePause" %al-source-pause) :void (source :unsigned-int))
(cffi:defcfun ("alSourceStop" %al-source-stop) :void (source :unsigned-int))
(cffi:defcfun ("alSourceRewind" %al-source-rewind) :void (source :unsigned-int))
(cffi:defcfun ("alSourceQueueBuffers" %al-source-queue-buffers) :void
  (source :unsigned-int) (count :int) (buffers :pointer))
(cffi:defcfun ("alSourceUnqueueBuffers" %al-source-unqueue-buffers) :void
  (source :unsigned-int) (count :int) (buffers :pointer))
(cffi:defcfun ("alGetSourcei" %al-get-source-i) :void (source :unsigned-int) (param :int) (value :pointer))
(cffi:defcfun ("alListenerf" %al-listener-f) :void (param :int) (value :float))
(cffi:defcfun ("alListener3f" %al-listener-3f) :void (param :int) (x :float) (y :float) (z :float))
(cffi:defcfun ("alListenerfv" %al-listener-fv) :void (param :int) (values :pointer))
(cffi:defcfun ("alGetError" %al-get-error) :int)

(defun %ensure-openal () (lwlgl.core:ensure-native-module :openal))

(defun open-device (&optional name)
  (%ensure-openal)
  (if name
      (cffi:with-foreign-string (pointer name) (%alc-open-device pointer))
      (%alc-open-device (cffi:null-pointer))))

(defun close-device (device) (not (zerop (%alc-close-device device))))
(defun create-context (device) (%alc-create-context device (cffi:null-pointer)))
(defun destroy-context (context) (%alc-destroy-context context))
(defun make-context-current (context) (not (zerop (%alc-make-context-current context))))
(defun buffer-data (buffer format data size frequency) (%al-buffer-data buffer format data size frequency))
(defun source-i (source param value) (%al-source-i source param value))
(defun source-f (source param value) (%al-source-f source param (coerce value 'single-float)))
(defun source-3f (source param x y z)
  (%al-source-3f source param (coerce x 'single-float) (coerce y 'single-float) (coerce z 'single-float)))
(defun source-play (source) (%al-source-play source))
(defun source-pause (source) (%al-source-pause source))
(defun source-stop (source) (%al-source-stop source))
(defun source-rewind (source) (%al-source-rewind source))
(defun listener-f (param value) (%al-listener-f param (coerce value 'single-float)))
(defun listener-3f (param x y z)
  (%al-listener-3f param (coerce x 'single-float) (coerce y 'single-float) (coerce z 'single-float)))
(defun listener-fv (param pointer) (%al-listener-fv param pointer))
(defun get-error () (%al-get-error))

(defun gen-buffer ()
  (cffi:with-foreign-object (value :unsigned-int)
    (%al-gen-buffers 1 value)
    (cffi:mem-ref value :unsigned-int)))

(defun delete-buffer (buffer)
  (cffi:with-foreign-object (value :unsigned-int)
    (setf (cffi:mem-ref value :unsigned-int) buffer)
    (%al-delete-buffers 1 value)))

(defun gen-source ()
  (cffi:with-foreign-object (value :unsigned-int)
    (%al-gen-sources 1 value)
    (cffi:mem-ref value :unsigned-int)))

(defun delete-source (source)
  (cffi:with-foreign-object (value :unsigned-int)
    (setf (cffi:mem-ref value :unsigned-int) source)
    (%al-delete-sources 1 value)))

(defun get-source-i (source param)
  (cffi:with-foreign-object (value :int)
    (%al-get-source-i source param value)
    (cffi:mem-ref value :int)))

(defun source-queue-buffers (source buffers)
  (let ((items (coerce buffers 'vector)))
    (lwlgl.core:with-foreign-array (pointer :unsigned-int items)
      (%al-source-queue-buffers source (length items) pointer)))
  source)

(defun source-unqueue-buffers (source count)
  (let ((result (make-array count :element-type '(unsigned-byte 32))))
    (cffi:with-foreign-object (pointer :unsigned-int count)
      (%al-source-unqueue-buffers source count pointer)
      (dotimes (i count result)
        (setf (aref result i) (cffi:mem-aref pointer :unsigned-int i))))))

;; ALC discovery and capture
(defconstant alc-default-device-specifier #x1004)
(defconstant alc-device-specifier #x1005)
(defconstant alc-default-all-devices-specifier #x1012)
(defconstant alc-all-devices-specifier #x1013)
(defconstant alc-capture-device-specifier #x0310)
(defconstant alc-capture-default-device-specifier #x0311)
(defconstant alc-capture-samples #x0312)

(cffi:defcfun ("alcGetString" %alc-get-string) :pointer (device :pointer) (param :int))
(cffi:defcfun ("alcIsExtensionPresent" %alc-is-extension-present) :unsigned-char (device :pointer) (extension :string))
(cffi:defcfun ("alcGetIntegerv" %alc-get-integerv) :void (device :pointer) (param :int) (size :int) (values :pointer))
(cffi:defcfun ("alcCaptureOpenDevice" %alc-capture-open-device) :pointer
  (name :pointer) (frequency :unsigned-int) (format :int) (buffer-size :int))
(cffi:defcfun ("alcCaptureCloseDevice" %alc-capture-close-device) :unsigned-char (device :pointer))
(cffi:defcfun ("alcCaptureStart" %alc-capture-start) :void (device :pointer))
(cffi:defcfun ("alcCaptureStop" %alc-capture-stop) :void (device :pointer))
(cffi:defcfun ("alcCaptureSamples" %alc-capture-samples) :void (device :pointer) (buffer :pointer) (samples :int))

(defun %alc-extension-present-p (extension &optional device)
  (%ensure-openal)
  (not (zerop (%alc-is-extension-present (or device (cffi:null-pointer)) extension))))

(defun %alc-single-string (param &optional device)
  (%ensure-openal)
  (let ((pointer (%alc-get-string (or device (cffi:null-pointer)) param)))
    (unless (cffi:null-pointer-p pointer)
      (cffi:foreign-string-to-lisp pointer))))

(defun %alc-string-list (param &optional device)
  (%ensure-openal)
  (let ((pointer (%alc-get-string (or device (cffi:null-pointer)) param)))
    (when (cffi:null-pointer-p pointer) (return-from %alc-string-list nil))
    (loop with offset = 0
          with result = '()
          for first = (cffi:mem-aref pointer :unsigned-char offset)
          until (zerop first)
          do (let* ((end (loop for index from offset
                               when (zerop (cffi:mem-aref pointer :unsigned-char index))
                                 return index))
                    (string (cffi:foreign-string-to-lisp
                             (cffi:inc-pointer pointer offset)
                             :count (- end offset))))
               (push string result)
               (setf offset (1+ end)))
          finally (return (nreverse result)))))

(defun openal-devices ()
  "Enumerates playback devices when the OpenAL implementation exposes enumeration extensions."
  (cond ((%alc-extension-present-p "ALC_ENUMERATE_ALL_EXT") (%alc-string-list alc-all-devices-specifier))
        ((%alc-extension-present-p "ALC_ENUMERATION_EXT") (%alc-string-list alc-device-specifier))
        (t nil)))

(defun default-openal-device ()
  (if (%alc-extension-present-p "ALC_ENUMERATE_ALL_EXT")
      (%alc-single-string alc-default-all-devices-specifier)
      (%alc-single-string alc-default-device-specifier)))

(defun capture-devices ()
  (if (%alc-extension-present-p "ALC_EXT_CAPTURE")
      (%alc-string-list alc-capture-device-specifier)
      nil))

(defun default-capture-device ()
  (when (%alc-extension-present-p "ALC_EXT_CAPTURE")
    (%alc-single-string alc-capture-default-device-specifier)))

(defun open-capture-device (&key name (sample-rate 44100) (format format-mono16) (buffer-samples 4096))
  (%ensure-openal)
  (if name
      (cffi:with-foreign-string (pointer name)
        (%alc-capture-open-device pointer sample-rate format buffer-samples))
      (%alc-capture-open-device (cffi:null-pointer) sample-rate format buffer-samples)))

(defun close-capture-device (device) (not (zerop (%alc-capture-close-device device))))
(defun start-capture (device) (%alc-capture-start device) device)
(defun stop-capture (device) (%alc-capture-stop device) device)

(defun available-capture-samples (device)
  (cffi:with-foreign-object (value :int)
    (%alc-get-integerv device alc-capture-samples 1 value)
    (cffi:mem-ref value :int)))

(defun capture-samples (device sample-count &key (channels 1) (bits-per-sample 16))
  "Captures SAMPLE-COUNT sample frames. Currently supports 8/16-bit mono or stereo data.
Returns a specialized vector containing interleaved channel samples."
  (check-type sample-count (integer 0 *))
  (let ((components (* sample-count channels)))
    (ecase bits-per-sample
      (8
       (let ((result (make-array components :element-type '(unsigned-byte 8))))
         (cffi:with-foreign-object (buffer :unsigned-char components)
           (%alc-capture-samples device buffer sample-count)
           (dotimes (i components result)
             (setf (aref result i) (cffi:mem-aref buffer :unsigned-char i))))))
      (16
       (let ((result (make-array components :element-type '(signed-byte 16))))
         (cffi:with-foreign-object (buffer :short components)
           (%alc-capture-samples device buffer sample-count)
           (dotimes (i components result)
             (setf (aref result i) (cffi:mem-aref buffer :short i)))))))))

(defmacro with-capture-device ((var &rest options) &body body)
  `(let ((,var (open-capture-device ,@options)))
     (when (or (null ,var) (cffi:null-pointer-p ,var))
       (error "Could not open OpenAL capture device."))
     (unwind-protect (progn ,@body)
       (close-capture-device ,var))))
