(defpackage #:lwlgl.openal
  (:use #:cl)
  (:shadow #:position)
  (:export
   #:create #:destroy #:get-function-provider
   #:al-capabilities #:al-capabilities-p
   #:create-capabilities #:get-capabilities #:set-capabilities
   #:with-capabilities #:al-function-available-p
   ;; Device/context
   #:open-device #:close-device #:create-context #:destroy-context #:make-context-current #:with-openal
   #:openal-devices #:default-openal-device
   #:capture-devices #:default-capture-device #:open-capture-device #:close-capture-device
   #:start-capture #:stop-capture #:available-capture-samples #:capture-samples #:with-capture-device
   ;; Buffers/sources
   #:gen-buffer #:delete-buffer #:buffer-data #:gen-source #:delete-source
   #:source-i #:source-f #:source-3f #:source-play #:source-pause #:source-stop #:source-rewind
   #:source-queue-buffers #:source-unqueue-buffers #:get-source-i
   #:listener-f #:listener-3f #:listener-fv #:get-error
   ;; Constants
   #:format-mono8 #:format-mono16 #:format-stereo8 #:format-stereo16
   #:pitch #:position #:direction #:velocity #:looping #:buffer-binding #:gain
   #:source-state #:initial #:playing #:paused #:stopped #:buffers-queued #:buffers-processed
   #:orientation #:source-relative
   ;; Helpers
   #:make-sine-wave #:play-pcm16 #:wait-source #:set-listener-orientation
   #:queue-pcm16 #:unqueue-processed-buffers
   ;; WAV
   #:wav-data #:wav-data-bytes #:wav-data-sample-rate #:wav-data-channels #:wav-data-bits-per-sample
   #:load-wav #:wav-format #:play-wav))
