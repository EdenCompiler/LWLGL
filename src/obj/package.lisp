(defpackage #:lwlgl.obj
  (:use #:cl)
  (:export
   #:obj-error #:obj-error-line #:obj-error-message
   #:obj-mesh #:obj-mesh-vertices #:obj-mesh-indices #:obj-mesh-vertex-count #:obj-mesh-triangle-count
   #:obj-mesh-has-normals-p #:obj-mesh-has-texcoords-p #:obj-mesh-bounds #:obj-mesh-source
   #:+obj-vertex-stride-floats+ #:load-obj #:parse-obj))
