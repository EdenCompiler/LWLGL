(defpackage #:lwlgl.math
  (:use #:cl)
  (:export
   ;; Vectors
   #:vec2 #:vec2-p #:vec2-x #:vec2-y
   #:vec3 #:vec3-p #:vec3-x #:vec3-y #:vec3-z
   #:vec4 #:vec4-p #:vec4-x #:vec4-y #:vec4-z #:vec4-w
   #:vec-add #:vec-sub #:vec-scale #:vec-hadamard #:vec-dot #:vec-cross
   #:vec-length #:vec-length-squared #:vec-normalize #:vec-distance #:vec-lerp
   ;; 4x4 matrices (column-major, OpenGL friendly)
   #:mat4-p #:make-mat4 #:identity-mat4 #:mat4-copy #:mat4-ref
   #:mat4-mul #:mat4-transpose #:mat4-determinant #:mat4-inverse
   #:translation-mat4 #:scale-mat4 #:rotation-x-mat4 #:rotation-y-mat4 #:rotation-z-mat4
   #:orthographic-mat4 #:perspective-mat4 #:look-at-mat4
   #:transform-point #:transform-direction #:project-point #:unproject-point
   ;; Quaternions / transforms
   #:quat #:quat-p #:quat-x #:quat-y #:quat-z #:quat-w #:identity-quat
   #:quat-length #:quat-length-squared #:quat-normalize #:quat-conjugate #:quat-inverse
   #:quat-mul #:quat-dot #:quat-from-axis-angle #:quat-from-euler #:quat-slerp #:quat->mat4
   #:quat-rotate-vector #:trs-mat4
   ;; Geometry
   #:aabb #:aabb-p #:aabb-min #:aabb-max #:aabb-from-points #:aabb-center #:aabb-extents #:aabb-size
   #:aabb-contains-point-p #:aabb-intersects-p #:transform-aabb
   #:ray #:ray-p #:ray-origin #:ray-direction #:ray-at #:ray-aabb-intersection
   #:degrees->radians #:radians->degrees))
