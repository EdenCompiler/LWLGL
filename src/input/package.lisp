(defpackage #:lwlgl.input
  (:use #:cl)
  (:export
   #:input-state #:make-input-state #:attach-input-state #:detach-input-state
   #:begin-input-frame #:input-attached-p
   #:key-down-p #:key-pressed-p #:key-released-p
   #:mouse-down-p #:mouse-pressed-p #:mouse-released-p
   #:mouse-position #:mouse-delta #:scroll-delta
   #:input-focused-p #:text-input #:consume-text-input
   ;; Named actions and digital axes
   #:action-map #:make-action-map #:key-binding #:mouse-binding #:chord-binding #:any-binding
   #:bind-action #:add-action-binding #:unbind-action #:action-bindings
   #:action-down-p #:action-pressed-p #:action-released-p #:action-map-names
   #:bind-axis #:unbind-axis #:axis-value #:axis-map-names
   #:bind-axis2 #:unbind-axis2 #:axis2-value #:axis2-map-names))
