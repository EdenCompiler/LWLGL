(defpackage #:lwlgl.core
  (:use #:cl)
  (:import-from #:cffi
                #:foreign-alloc #:foreign-free #:foreign-type-size
                #:mem-aref #:null-pointer #:null-pointer-p
                #:pointer-address #:inc-pointer #:with-foreign-object)
  (:export
   ;; Versão e plataforma
   #:*lwlgl-version* #:platform #:architecture #:shared-library-extension
   #:with-native-floating-point-environment
   #:platform-library-names
   ;; Condições
   #:lwlgl-error #:native-library-error #:native-library-error-module
   #:native-library-error-cause #:unsupported-platform
   #:missing-native-symbol #:missing-native-symbol-name
   #:native-memory-error #:native-memory-error-buffer #:native-memory-error-reason
   ;; Registro de módulos
   #:native-module #:native-module-name #:native-module-libraries
   #:native-module-loaded-p #:native-module-handle
   #:register-native-module #:find-native-module #:list-native-modules
   #:ensure-native-module #:unload-native-module #:with-native-module
   #:native-platform-triple #:*native-bundle-roots* #:add-native-bundle-root
   #:native-library-candidates
   ;; Memória
   #:native-buffer #:native-buffer-pointer #:native-buffer-length
   #:native-buffer-element-type #:native-buffer-owned-p
   #:native-buffer-capacity-bytes #:native-buffer-element-size
   #:native-buffer-alignment #:native-buffer-read-only-p #:native-buffer-parent
   #:native-buffer-position #:native-buffer-limit #:native-buffer-remaining
   #:make-native-buffer #:free-native-buffer #:buffer-ref #:buffer-set
   #:buffer-get #:buffer-put #:clear-native-buffer #:flip-native-buffer #:rewind-native-buffer
   #:wrap-native-buffer #:slice-native-buffer #:native-buffer-alive-p
   #:fill-native-buffer #:copy-native-buffer
   #:make-pointer-buffer #:string-to-utf8-buffer #:utf8-buffer-to-string
   #:make-byte-buffer #:make-short-buffer #:make-int-buffer #:make-long-buffer
   #:make-float-buffer #:make-double-buffer
   #:mem-alloc #:mem-calloc #:mem-free #:mem-address #:mem-utf8
   #:with-native-buffer #:with-stack-allocation #:with-foreign-array
   #:foreign-array-from-sequence #:copy-foreign-array-to-list
   #:native-arena #:make-native-arena #:native-arena-active-p
   #:arena-alloc #:free-native-arena #:with-native-arena
   #:memory-stack #:make-memory-stack #:free-memory-stack #:memory-stack-active-p
   #:*memory-stack* #:current-memory-stack #:stack-push #:stack-pop
   #:stack-malloc #:stack-calloc #:with-memory-stack
   ;; Function providers, capabilities, handles and callbacks
   #:function-provider #:make-function-provider #:function-provider-name
   #:function-provider-resolver #:get-function-address
   #:api-capabilities #:make-api-capabilities #:api-capabilities-api
   #:api-capabilities-version #:api-capabilities-functions #:api-capabilities-features
   #:capability-function-pointer #:capability-supported-p #:require-capability-function
   #:dispatchable-handle #:make-dispatchable-handle #:dispatchable-handle-pointer
   #:dispatchable-handle-capabilities #:dispatchable-handle-parent
   #:callback-resource #:make-callback-resource #:callback-resource-pointer
   #:callback-resource-function #:callback-resource-active-p #:free-callback
   #:with-callback
   ;; Runtime configuration
   #:runtime-configuration #:*runtime-configuration*
   #:runtime-configuration-checks-enabled-p #:runtime-configuration-debug-memory-p
   #:runtime-configuration-debug-loader-p #:configure-runtime
   ;; Runtime e diagnóstico
   #:*debug-native-loading* #:*native-search-paths*
   #:add-native-search-path #:runtime-report #:print-runtime-report
   #:resolve-foreign-symbol #:foreign-symbol-available-p))
