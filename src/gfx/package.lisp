(defpackage #:lwlgl.gfx
  (:use #:cl)
  (:export
   #:shader-include-error #:shader-include-error-path #:shader-include-error-stack
   #:preprocess-shader #:make-program-from-files
   #:load-texture-2d
   #:gpu-mesh #:gpu-mesh-vao #:gpu-mesh-vbo #:gpu-mesh-ebo #:gpu-mesh-index-count
   #:upload-obj-mesh #:draw-gpu-mesh #:delete-gpu-mesh #:with-gpu-mesh))
