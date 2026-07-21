(in-package #:lwlgl.examples)

(defun toolbox-demo ()
  "Runs a device-free tour of LWLGL 0.3 math, OBJ and profiling utilities."
  (let* ((rotation (lwlgl.math:quat-from-axis-angle (lwlgl.math:vec3 0 0 1)
                                                     (lwlgl.math:degrees->radians 90)))
         (rotated (lwlgl.math:quat-rotate-vector rotation (lwlgl.math:vec3 1 0 0)))
         (mesh (lwlgl.obj:parse-obj
                "v -1 0 0
                 v 1 0 0
                 v 1 1 0
                 v -1 1 0
                 vt 0 0
                 vt 1 0
                 vt 1 1
                 vt 0 1
                 f 1/1 2/2 3/3 4/4
                "
                :source "inline-quad.obj"))
         (profiler (lwlgl.util:make-profiler)))
    (lwlgl.util:with-profiled-section (profiler :small-workload)
      (loop repeat 10000 do (sqrt 2.0d0)))
    (format t "~&Rotated (1,0,0) -> (~,3F, ~,3F, ~,3F)~%"
            (lwlgl.math:vec3-x rotated) (lwlgl.math:vec3-y rotated) (lwlgl.math:vec3-z rotated))
    (format t "OBJ: ~D vertices, ~D triangles, ~D indices~%"
            (lwlgl.obj:obj-mesh-vertex-count mesh)
            (lwlgl.obj:obj-mesh-triangle-count mesh)
            (length (lwlgl.obj:obj-mesh-indices mesh)))
    (dolist (stat (lwlgl.util:profiler-report profiler))
      (format t "Profile ~A: ~,6F s~%"
              (lwlgl.util:profile-stat-name stat)
              (lwlgl.util:profile-stat-total stat)))
    (values rotated mesh profiler)))
