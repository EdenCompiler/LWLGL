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
   #:make-native-buffer #:free-native-buffer #:buffer-ref #:buffer-set
   #:wrap-native-buffer #:slice-native-buffer #:native-buffer-alive-p
   #:fill-native-buffer #:copy-native-buffer
   #:with-native-buffer #:with-stack-allocation #:with-foreign-array
   #:foreign-array-from-sequence #:copy-foreign-array-to-list
   #:native-arena #:make-native-arena #:native-arena-active-p
   #:arena-alloc #:free-native-arena #:with-native-arena
   ;; Runtime configuration
   #:runtime-configuration #:*runtime-configuration*
   #:runtime-configuration-checks-enabled-p #:runtime-configuration-debug-memory-p
   #:runtime-configuration-debug-loader-p #:configure-runtime
   ;; Runtime e diagnóstico
   #:*debug-native-loading* #:*native-search-paths*
   #:add-native-search-path #:runtime-report #:print-runtime-report
   #:resolve-foreign-symbol #:foreign-symbol-available-p))
