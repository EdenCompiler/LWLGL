(in-package #:lwlgl.tests)

(defvar *failures* 0)
(defvar *checks* 0)

(defmacro check (form)
  `(progn
     (incf *checks*)
     (unless ,form
       (incf *failures*)
       (format *error-output* "~&FAIL: ~S~%" ',form))))

(defun approximately= (a b &optional (epsilon 1.0e-4))
  (<= (abs (- a b)) epsilon))

(defun test-native-buffer ()
  (lwlgl.core:with-native-buffer (buffer :int 4 :initial-element 0)
    (setf (lwlgl.core:buffer-ref buffer 2) 42)
    (check (= 42 (lwlgl.core:buffer-ref buffer 2)))
    (check (= 4 (lwlgl.core:native-buffer-length buffer)))))

(defun test-module-registry ()
  (lwlgl.core:register-native-module :lwlgl-test '("definitely-not-loaded"))
  (check (lwlgl.core:find-native-module :lwlgl-test))
  (check (member :lwlgl-test (mapcar #'lwlgl.core:native-module-name
                                      (lwlgl.core:list-native-modules)))))

(defun test-platform ()
  (check (member (lwlgl.core:platform) '(:windows :macos :linux :unknown)))
  (check (string= "0.3.2" lwlgl.core:*lwlgl-version*)))

(defun test-vectors ()
  (let* ((a (lwlgl.math:vec3 1 2 3))
         (b (lwlgl.math:vec3 4 5 6))
         (sum (lwlgl.math:vec-add a b))
         (cross (lwlgl.math:vec-cross a b)))
    (check (= 5.0 (lwlgl.math:vec3-x sum)))
    (check (= 7.0 (lwlgl.math:vec3-y sum)))
    (check (= 9.0 (lwlgl.math:vec3-z sum)))
    (check (= 32.0 (lwlgl.math:vec-dot a b)))
    (check (= -3.0 (lwlgl.math:vec3-x cross)))
    (check (= 6.0 (lwlgl.math:vec3-y cross)))
    (check (= -3.0 (lwlgl.math:vec3-z cross)))))

(defun test-matrices ()
  (let* ((translation (lwlgl.math:translation-mat4 3 4 5))
         (point (lwlgl.math:transform-point translation (lwlgl.math:vec3 1 2 3)))
         (inverse (lwlgl.math:mat4-inverse translation))
         (identity (lwlgl.math:mat4-mul translation inverse)))
    (check (= 4.0 (lwlgl.math:vec3-x point)))
    (check (= 6.0 (lwlgl.math:vec3-y point)))
    (check (= 8.0 (lwlgl.math:vec3-z point)))
    (dotimes (row 4)
      (dotimes (column 4)
        (check (approximately= (lwlgl.math:mat4-ref identity row column)
                               (if (= row column) 1.0 0.0)))))))

(defun test-quaternions ()
  (let* ((rotation (lwlgl.math:quat-from-axis-angle (lwlgl.math:vec3 0 0 1)
                                                     (lwlgl.math:degrees->radians 90)))
         (rotated (lwlgl.math:quat-rotate-vector rotation (lwlgl.math:vec3 1 0 0))))
    (check (approximately= 0.0 (lwlgl.math:vec3-x rotated)))
    (check (approximately= 1.0 (lwlgl.math:vec3-y rotated)))
    (check (approximately= 0.0 (lwlgl.math:vec3-z rotated)))))

(defun test-geometry ()
  (let* ((box (lwlgl.math:aabb (lwlgl.math:vec3 -1 -1 -1) (lwlgl.math:vec3 1 1 1)))
         (ray (lwlgl.math:ray (lwlgl.math:vec3 -5 0 0) (lwlgl.math:vec3 1 0 0))))
    (check (lwlgl.math:aabb-contains-point-p box (lwlgl.math:vec3 0 0 0)))
    (multiple-value-bind (near far) (lwlgl.math:ray-aabb-intersection ray box)
      (check (approximately= 4.0 near))
      (check (approximately= 6.0 far)))))

(defun test-fixed-step ()
  (let ((stepper (lwlgl.util:make-fixed-step :hz 10.0d0))
        (calls 0))
    (multiple-value-bind (alpha steps)
        (lwlgl.util:advance-fixed-step stepper 0.25d0 (lambda (dt) (declare (ignore dt)) (incf calls)))
      (check (= calls 2))
      (check (= steps 2))
      (check (approximately= alpha 0.5d0)))))

(defun test-profiler ()
  (let ((profiler (lwlgl.util:make-profiler)))
    (lwlgl.util:profiler-record profiler :update 0.01d0)
    (lwlgl.util:profiler-record profiler :update 0.03d0)
    (let ((stat (lwlgl.util:profiler-stat profiler :update)))
      (check (= 2 (lwlgl.util:profile-stat-count stat)))
      (check (approximately= 0.02d0 (lwlgl.util:profile-stat-average stat))))))

(defun test-obj ()
  (let ((mesh (lwlgl.obj:parse-obj
               "v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
vt 0 0
vt 1 0
vt 1 1
vt 0 1
f 1/1 2/2 3/3 4/4
")))
    (check (= 4 (lwlgl.obj:obj-mesh-vertex-count mesh)))
    (check (= 2 (lwlgl.obj:obj-mesh-triangle-count mesh)))
    (check (= 6 (length (lwlgl.obj:obj-mesh-indices mesh))))
    (check (= 32 (length (lwlgl.obj:obj-mesh-vertices mesh))))
    (check (lwlgl.obj:obj-mesh-has-texcoords-p mesh))))

(defun test-assets ()
  (let ((manager (lwlgl.assets:make-asset-manager :roots nil)))
    (lwlgl.assets:register-asset-loader manager "txt" #'lwlgl.assets:load-text-file)
    (check (functionp (lwlgl.assets:asset-loader manager "TXT")))
    (check (= 0 (lwlgl.assets:asset-cache-size manager)))))

(defun run-tests ()
  (setf *failures* 0 *checks* 0)
  (test-native-buffer)
  (test-module-registry)
  (test-platform)
  (test-vectors)
  (test-matrices)
  (test-quaternions)
  (test-geometry)
  (test-fixed-step)
  (test-profiler)
  (test-obj)
  (test-assets)
  (format t "~&LWLGL tests: ~A checks, ~A failures.~%" *checks* *failures*)
  (when (plusp *failures*) (error "LWLGL tests failed."))
  t)
