(defpackage #:lwlgl.core
  (:use #:cl)
  (:import-from #:cffi
                #:foreign-alloc #:foreign-free #:foreign-type-size
                #:mem-aref #:null-pointer #:null-pointer-p
                #:pointer-address #:with-foreign-object)
  (:export
   ;; Versão e plataforma
   #:*lwlgl-version* #:platform #:architecture #:shared-library-extension
   #:with-native-floating-point-environment
   #:platform-library-names
   ;; Condições
   #:lwlgl-error #:native-library-error #:native-library-error-module
   #:native-library-error-cause #:unsupported-platform
   #:missing-native-symbol #:missing-native-symbol-name
   ;; Registro de módulos
   #:native-module #:native-module-name #:native-module-libraries
   #:native-module-loaded-p #:native-module-handle
   #:register-native-module #:find-native-module #:list-native-modules
   #:ensure-native-module #:unload-native-module #:with-native-module
   ;; Memória
   #:native-buffer #:native-buffer-pointer #:native-buffer-length
   #:native-buffer-element-type #:native-buffer-owned-p
   #:make-native-buffer #:free-native-buffer #:buffer-ref #:buffer-set
   #:with-native-buffer #:with-stack-allocation #:with-foreign-array
   #:foreign-array-from-sequence #:copy-foreign-array-to-list
   ;; Runtime e diagnóstico
   #:*debug-native-loading* #:*native-search-paths*
   #:add-native-search-path #:runtime-report #:print-runtime-report
   #:resolve-foreign-symbol #:foreign-symbol-available-p))
