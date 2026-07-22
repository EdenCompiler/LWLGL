(defpackage #:lwlgl.glfw
  (:use #:cl)
  (:import-from #:lwlgl.core #:ensure-native-module #:register-native-module
                #:platform-library-names #:with-native-floating-point-environment)
  (:export
   ;; Lifecycle/version/events
   #:init #:terminate #:with-glfw #:version-string #:get-version #:init-hint #:last-error #:glfw-diagnostics
   #:*glfw-platform-preference* #:*disable-wayland-libdecor*
   #:init-platform #:wayland-libdecor #:any-platform #:platform-win32 #:platform-cocoa
   #:platform-wayland #:platform-x11 #:platform-null #:wayland-prefer-libdecor #:wayland-disable-libdecor
   #:get-time #:set-time
   #:poll-events #:wait-events #:wait-events-timeout #:post-empty-event
   ;; Window
   #:window #:window-handle #:window-title #:window-width #:window-height
   #:create-window #:destroy-window #:with-window #:make-context-current #:current-context
   #:swap-buffers #:swap-interval #:window-should-close-p #:set-window-should-close
   #:framebuffer-size #:window-size #:set-window-size #:window-position #:set-window-position
   #:set-window-title #:show-window #:hide-window #:focus-window
   #:iconify-window #:restore-window #:maximize-window #:window-attrib #:run-loop
   #:window-content-scale #:window-opacity #:set-window-opacity #:request-window-attention
   ;; Input
   #:press #:release #:repeat
   #:key-unknown #:key-space #:key-apostrophe #:key-comma #:key-minus #:key-period #:key-slash
   #:key-0 #:key-1 #:key-2 #:key-3 #:key-4 #:key-5 #:key-6 #:key-7 #:key-8 #:key-9
   #:key-a #:key-b #:key-c #:key-d #:key-e #:key-f #:key-g #:key-h #:key-i #:key-j
   #:key-k #:key-l #:key-m #:key-n #:key-o #:key-p #:key-q #:key-r #:key-s #:key-t
   #:key-u #:key-v #:key-w #:key-x #:key-y #:key-z
   #:key-escape #:key-enter #:key-tab #:key-backspace #:key-insert #:key-delete
   #:key-right #:key-left #:key-down #:key-up #:key-page-up #:key-page-down #:key-home #:key-end
   #:key-f1 #:key-f2 #:key-f3 #:key-f4 #:key-f5 #:key-f6 #:key-f7 #:key-f8 #:key-f9 #:key-f10 #:key-f11 #:key-f12
   #:key-left-shift #:key-left-control #:key-left-alt #:key-left-super
   #:key-right-shift #:key-right-control #:key-right-alt #:key-right-super
   #:mod-shift #:mod-control #:mod-alt #:mod-super #:mod-caps-lock #:mod-num-lock
   #:mouse-button-left #:mouse-button-right #:mouse-button-middle
   #:get-key #:get-mouse-button #:cursor-position #:set-cursor-position
   #:get-input-mode #:set-input-mode #:raw-mouse-motion-supported-p
   #:cursor #:sticky-keys #:sticky-mouse-buttons #:lock-key-mods #:raw-mouse-motion
   #:cursor-normal #:cursor-hidden #:cursor-disabled #:cursor-captured
   #:clipboard-string #:set-clipboard-string
   ;; Callbacks
   #:set-key-handler #:add-key-handler #:remove-key-handler
   #:set-char-handler #:add-char-handler #:remove-char-handler
   #:set-framebuffer-size-handler #:add-framebuffer-size-handler #:remove-framebuffer-size-handler
   #:set-window-size-handler #:add-window-size-handler #:remove-window-size-handler
   #:set-cursor-position-handler #:add-cursor-position-handler #:remove-cursor-position-handler
   #:set-scroll-handler #:add-scroll-handler #:remove-scroll-handler
   #:set-mouse-button-handler #:add-mouse-button-handler #:remove-mouse-button-handler
   #:set-focus-handler #:add-focus-handler #:remove-focus-handler
   #:set-close-handler #:add-close-handler #:remove-close-handler
   #:set-drop-handler #:add-drop-handler #:remove-drop-handler
   ;; Hints/attributes
   #:default-window-hints #:window-hint #:client-api #:no-api #:opengl-api #:opengl-es-api
   #:context-version-major #:context-version-minor #:opengl-profile
   #:opengl-core-profile #:opengl-compat-profile #:opengl-forward-compat
   #:resizable #:visible #:decorated #:focused #:auto-iconify #:floating #:maximized
   #:center-cursor #:transparent-framebuffer #:focus-on-show #:scale-to-monitor
   #:true #:false
   ;; Monitors/video modes
   #:monitor #:monitor-handle #:monitor-name #:get-monitors #:primary-monitor
   #:monitor-position #:monitor-content-scale #:monitor-physical-size
   #:video-mode #:video-mode-width #:video-mode-height #:video-mode-red-bits
   #:video-mode-green-bits #:video-mode-blue-bits #:video-mode-refresh-rate
   #:monitor-video-mode #:monitor-video-modes
   ;; Joysticks/gamepads
   #:joystick-present-p #:joystick-name #:joystick-guid #:joystick-axes #:joystick-buttons #:joystick-hats
   #:joystick-is-gamepad-p #:gamepad-name #:gamepad-state
   #:joystick-1 #:joystick-last
   #:gamepad-button-a #:gamepad-button-b #:gamepad-button-x #:gamepad-button-y
   #:gamepad-button-left-bumper #:gamepad-button-right-bumper #:gamepad-button-back
   #:gamepad-button-start #:gamepad-button-guide #:gamepad-button-left-thumb #:gamepad-button-right-thumb
   #:gamepad-button-dpad-up #:gamepad-button-dpad-right #:gamepad-button-dpad-down #:gamepad-button-dpad-left
   #:gamepad-axis-left-x #:gamepad-axis-left-y #:gamepad-axis-right-x #:gamepad-axis-right-y
   #:gamepad-axis-left-trigger #:gamepad-axis-right-trigger
   ;; Interop
   #:get-proc-address #:raw-window-pointer
   #:vulkan-supported-p #:required-vulkan-instance-extensions #:create-window-surface))
