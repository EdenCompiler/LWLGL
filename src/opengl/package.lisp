(defpackage #:lwlgl.opengl
  (:use #:cl)
  (:shadow #:fill #:program-error)
  (:export
   ;; Loader/capabilities
   #:load-opengl #:reload-opengl #:opengl-loaded-p #:gl-capabilities
   #:create-gl-capabilities #:create-capabilities #:get-capabilities #:set-capabilities
   #:with-gl-capabilities #:with-capabilities #:*current-gl-capabilities*
   #:gl-capabilities-p #:gl-capabilities-functions #:gl-capabilities-missing-required
   #:gl-capabilities-context-address #:gl-capabilities-loaded-at #:gl-capabilities-complete-p
   #:gl-function-available-p #:require-gl-function #:define-gl-function #:gl-info #:gl-extensions
   #:gl-function-metadata #:registered-gl-functions
   ;; Core constants
   #:false-value #:true-value
   #:color-buffer-bit #:depth-buffer-bit #:stencil-buffer-bit
   #:points #:lines #:line-strip #:triangles #:triangle-strip #:triangle-fan
   #:array-buffer #:element-array-buffer #:uniform-buffer #:pixel-pack-buffer #:pixel-unpack-buffer
   #:stream-draw #:static-draw #:dynamic-draw #:stream-read #:static-read #:dynamic-read
   #:byte-type #:unsigned-byte-type #:short-type #:unsigned-short-type #:int-type #:unsigned-int #:float-type
   #:vertex-shader #:fragment-shader #:geometry-shader #:tess-control-shader #:tess-evaluation-shader
   #:compile-status #:link-status #:info-log-length
   #:texture-1d #:texture-2d #:texture-3d #:texture-cube-map #:texture0
   #:red #:rg #:rgb #:rgba #:bgr #:bgra #:r8 #:rg8 #:rgb8 #:rgba8 #:srgb8 #:srgb8-alpha8
   #:texture-mag-filter #:texture-min-filter #:texture-wrap-s #:texture-wrap-t #:texture-wrap-r
   #:nearest #:linear #:nearest-mipmap-nearest #:linear-mipmap-nearest #:nearest-mipmap-linear #:linear-mipmap-linear
   #:repeat-texture #:mirrored-repeat #:clamp-to-edge #:clamp-to-border
   #:blend #:depth-test #:cull-face #:scissor-test #:multisample
   #:src-alpha #:one-minus-src-alpha #:one #:zero #:func-add #:func-subtract
   #:less #:lequal #:greater #:gequal #:always #:never
   #:front #:back #:front-and-back #:cw #:ccw #:fill #:line-mode #:point-mode
   #:framebuffer #:read-framebuffer #:draw-framebuffer #:renderbuffer
   #:color-attachment0 #:depth-attachment #:stencil-attachment #:depth-stencil-attachment
   #:framebuffer-complete #:depth24-stencil8
   #:vendor-string #:renderer-string #:version-string #:extensions-string #:shading-language-version-string
   #:major-version #:minor-version #:num-extensions #:max-texture-size #:max-combined-texture-image-units
   #:unpack-alignment #:pack-alignment
   #:samples-passed #:any-samples-passed #:time-elapsed #:query-result #:query-result-available
   #:sync-gpu-commands-complete #:already-signaled #:timeout-expired #:condition-satisfied #:wait-failed
   #:sync-flush-commands-bit
   ;; Direct OpenGL calls
   #:gl-clear-color #:gl-clear #:gl-viewport #:gl-scissor
   #:gl-enable #:gl-disable #:gl-blend-func #:gl-blend-equation #:gl-depth-func #:gl-cull-face #:gl-front-face
   #:gl-polygon-mode #:gl-line-width
   #:gl-gen-buffers #:gl-delete-buffers #:gl-bind-buffer #:gl-buffer-data #:gl-buffer-sub-data #:gl-bind-buffer-base
   #:gl-gen-vertex-arrays #:gl-delete-vertex-arrays #:gl-bind-vertex-array
   #:gl-vertex-attrib-pointer #:gl-enable-vertex-attrib-array #:gl-disable-vertex-attrib-array #:gl-vertex-attrib-divisor
   #:gl-create-shader #:gl-shader-source #:gl-compile-shader #:gl-get-shader-iv #:gl-get-shader-info-log #:gl-delete-shader
   #:gl-create-program #:gl-attach-shader #:gl-detach-shader #:gl-link-program #:gl-get-program-iv
   #:gl-get-program-info-log #:gl-use-program #:gl-delete-program
   #:gl-get-attrib-location #:gl-get-uniform-location #:gl-get-uniform-block-index #:gl-uniform-block-binding
   #:gl-uniform-1f #:gl-uniform-2f #:gl-uniform-3f #:gl-uniform-4f
   #:gl-uniform-1i #:gl-uniform-2i #:gl-uniform-3i #:gl-uniform-4i
   #:gl-uniform-matrix-3fv #:gl-uniform-matrix-4fv
   #:gl-draw-arrays #:gl-draw-elements #:gl-draw-arrays-instanced #:gl-draw-elements-instanced
   #:gl-gen-textures #:gl-delete-textures #:gl-active-texture #:gl-bind-texture
   #:gl-tex-parameter-i #:gl-tex-image-2d #:gl-tex-sub-image-2d #:gl-generate-mipmap #:gl-pixel-store-i
   #:gl-gen-framebuffers #:gl-delete-framebuffers #:gl-bind-framebuffer #:gl-check-framebuffer-status
   #:gl-framebuffer-texture-2d #:gl-blit-framebuffer
   #:gl-gen-renderbuffers #:gl-delete-renderbuffers #:gl-bind-renderbuffer #:gl-renderbuffer-storage
   #:gl-framebuffer-renderbuffer
   #:gl-read-pixels #:gl-get-string #:gl-get-string-i #:gl-get-integer-v #:gl-get-error
   #:gl-gen-queries #:gl-delete-queries #:gl-begin-query #:gl-end-query
   #:gl-get-query-object-iv #:gl-get-query-object-ui64v
   #:gl-fence-sync #:gl-delete-sync #:gl-client-wait-sync #:gl-flush #:gl-finish
   ;; Helpers/resources
   #:make-buffer #:delete-buffer #:make-vertex-array #:delete-vertex-array
   #:make-texture #:delete-texture #:make-framebuffer #:delete-framebuffer #:make-renderbuffer #:delete-renderbuffer
   #:upload-floats #:upload-unsigned-ints #:upload-buffer-sub-data
   #:compile-shader #:link-program #:make-program #:shader-error #:shader-error-log #:program-error #:program-error-log
   #:get-string #:get-integer #:check-error #:set-uniform-mat4 #:set-uniform-mat3
   #:create-texture-2d #:create-color-framebuffer #:read-pixels-rgba
   #:make-query #:delete-query #:query-result-available-p #:query-result-ui64 #:with-query
   #:make-fence #:delete-fence #:wait-fence #:with-fence
   #:with-bound-buffer #:with-bound-vertex-array #:with-bound-texture #:with-bound-framebuffer #:with-program))
