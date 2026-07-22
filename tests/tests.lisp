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

(defun test-native-memory-views-and-arena ()
  (let ((owner (lwlgl.core:make-native-buffer :int 4 :initial-element 0 :alignment 16)))
    (unwind-protect
         (progn
           (check (zerop (mod (cffi:pointer-address (lwlgl.core:native-buffer-pointer owner)) 16)))
           (check (= 16 (lwlgl.core:native-buffer-capacity-bytes owner)))
           (setf (lwlgl.core:buffer-ref owner 1) 10
                 (lwlgl.core:buffer-ref owner 2) 20)
           (let ((view (lwlgl.core:slice-native-buffer owner 1 2)))
             (check (= 10 (lwlgl.core:buffer-ref view 0)))
             (setf (lwlgl.core:buffer-ref view 1) 30)
             (check (= 30 (lwlgl.core:buffer-ref owner 2)))
             (lwlgl.core:free-native-buffer owner)
             (check (not (lwlgl.core:native-buffer-alive-p view)))
             (check (handler-case (progn (lwlgl.core:buffer-ref view 0) nil)
                      (lwlgl.core:native-memory-error () t)))))
      (lwlgl.core:free-native-buffer owner)))
  (lwlgl.core:with-native-arena (arena)
    (let ((source (lwlgl.core:arena-alloc arena :float 3 :initial-element 2.0))
          (destination (lwlgl.core:arena-alloc arena :float 3 :initial-element 0.0)))
      (lwlgl.core:copy-native-buffer source destination)
      (check (= 2.0 (lwlgl.core:buffer-ref destination 2)))))
  (let ((arena (lwlgl.core:make-native-arena)))
    (lwlgl.core:free-native-arena arena)
    (check (not (lwlgl.core:native-arena-active-p arena)))))

(defun test-lwjgl-style-memory ()
  (lwlgl.core:with-native-buffer (buffer :int 4 :initial-element 0)
    (lwlgl.core:buffer-put buffer 11)
    (lwlgl.core:buffer-put buffer 22)
    (check (= 2 (lwlgl.core:native-buffer-position buffer)))
    (lwlgl.core:flip-native-buffer buffer)
    (check (= 2 (lwlgl.core:native-buffer-remaining buffer)))
    (check (= 11 (lwlgl.core:buffer-get buffer)))
    (check (= 22 (lwlgl.core:buffer-get buffer)))
    (check (handler-case (progn (lwlgl.core:buffer-get buffer) nil)
             (lwlgl.core:native-memory-error () t))))
  (lwlgl.core:with-memory-stack (stack :size 128)
    (let ((outer (lwlgl.core:stack-calloc :int 4 :stack stack)))
      (setf (lwlgl.core:buffer-ref outer 0) 7)
      (lwlgl.core:with-memory-stack (nested)
        (declare (ignore nested))
        (let ((inner (lwlgl.core:stack-malloc :float 4)))
          (check (= 4 (lwlgl.core:native-buffer-length inner)))))
      (check (= 7 (lwlgl.core:buffer-ref outer 0)))))
  (lwlgl.core:with-memory-stack (stack :size 64)
    (let ((floats (lwlgl.core:stack-calloc :float 2 :stack stack)))
      (check (= 0.0 (lwlgl.core:buffer-ref floats 0)))))
  (let ((utf8 (lwlgl.core:string-to-utf8-buffer "LWLGL λ")))
    (unwind-protect
         (check (string= "LWLGL λ" (lwlgl.core:utf8-buffer-to-string utf8)))
      (lwlgl.core:free-native-buffer utf8)))
  (let ((buffer (lwlgl.core:mem-calloc :int 2)))
    (unwind-protect
         (progn
           (check (zerop (lwlgl.core:buffer-ref buffer 0)))
           (check (= (cffi:pointer-address (lwlgl.core:native-buffer-pointer buffer))
                     (lwlgl.core:mem-address buffer))))
      (lwlgl.core:mem-free buffer))))

(defun test-runtime-configuration ()
  (let ((configuration (lwlgl.core:configure-runtime :checks-enabled-p t
                                                       :debug-memory-p t
                                                       :debug-loader-p nil)))
    (check (lwlgl.core:runtime-configuration-checks-enabled-p configuration))
    (check (lwlgl.core:runtime-configuration-debug-memory-p configuration))
    (check (not (lwlgl.core:runtime-configuration-debug-loader-p configuration))))
  (lwlgl.core:configure-runtime :debug-memory-p nil))

(defun test-dispatch-runtime ()
  (let* ((address (cffi:make-pointer 1234))
         (provider (lwlgl.core:make-function-provider
                    :name :test
                    :resolver (lambda (name) (and (string= name "present") address))))
         (functions (make-hash-table :test #'equal))
         (features (make-hash-table :test #'equal)))
    (setf (gethash "present" functions) address
          (gethash :test-10 features) t)
    (let ((caps (lwlgl.core:make-api-capabilities
                 :api :test :version '(1 0) :functions functions :features features)))
      (check (= 1234 (cffi:pointer-address
                      (lwlgl.core:get-function-address provider "present" :required t))))
      (check (null (lwlgl.core:get-function-address provider "missing")))
      (check (lwlgl.core:capability-supported-p caps :test-10))
      (check (= 1234 (cffi:pointer-address
                      (lwlgl.core:require-capability-function caps "present"))))
      (let ((handle (lwlgl.core:make-dispatchable-handle
                     :pointer address :capabilities caps)))
        (check (eq caps (lwlgl.core:dispatchable-handle-capabilities handle)))))
    (let ((released nil))
      (lwlgl.core:with-callback
          (callback (lwlgl.core:make-callback-resource
                     address #'identity :releaser (lambda (pointer)
                                                    (setf released (cffi:pointer-address pointer)))))
        (check (lwlgl.core:callback-resource-active-p callback)))
      (check (= 1234 released)))))

(defun test-binding-generator ()
  (let* ((path (asdf:system-relative-pathname :lwlgl/bindgen
                                              #P"bindings/opengl-bootstrap.sexp"))
         (spec (lwlgl.bindgen:read-binding-spec path))
         (source (lwlgl.bindgen:emit-binding-source spec))
         (fingerprint (lwlgl.bindgen:binding-spec-fingerprint spec)))
    (check (eq :opengl-bootstrap (lwlgl.bindgen:binding-spec-name spec)))
    (check (= 3 (length (lwlgl.bindgen:binding-spec-commands spec))))
    (check (= 16 (length fingerprint)))
    (check (search "Generated by LWLGL bindgen" source))
    (check (search "glClearColor" source))))

(defun test-opengl-binding-metadata ()
  (let ((metadata (lwlgl.opengl:gl-function-metadata "glClearColor")))
    (check (eq 'lwlgl.opengl:gl-clear-color (getf metadata :lisp-name)))
    (check (equal '((lwlgl.opengl::red-value :float)
                    (lwlgl.opengl::green :float)
                    (lwlgl.opengl::blue :float)
                    (lwlgl.opengl::alpha :float))
                  (getf metadata :arguments)))
    (check (>= (length (lwlgl.opengl:registered-gl-functions)) 90))
    (multiple-value-bind (raw status) (find-symbol "NGL-CLEAR-COLOR" :lwlgl.opengl.gl46)
      (check (eq :external status))
      (check (fboundp raw)))
    (multiple-value-bind (constant status) (find-symbol "+GL-COLOR-BUFFER-BIT+"
                                                         :lwlgl.opengl.gl46)
      (check (eq :external status))
      (check (= #x4000 (symbol-value constant))))))

(defun %external-function-p (name package)
  (multiple-value-bind (symbol status) (find-symbol name package)
    (and (eq status :external) (fboundp symbol))))

(defun test-lwjgl-api-surface ()
  (check (%external-function-p "GLFW-INIT" :lwlgl.glfw.glfw34))
  (check (%external-function-p "NGLFW-INIT" :lwlgl.glfw.glfw34))
  (check (%external-function-p "AL-SOURCE-PLAY" :lwlgl.openal.al11))
  (check (%external-function-p "NAL-SOURCE-PLAY" :lwlgl.openal.al11))
  (check (%external-function-p "CL-GET-PLATFORM-IDS" :lwlgl.opencl.cl30))
  (check (%external-function-p "NCL-GET-PLATFORM-IDS" :lwlgl.opencl.cl30))
  (check (%external-function-p "VK-GET-INSTANCE-PROC-ADDR" :lwlgl.vulkan.vk14))
  (check (%external-function-p "NVK-GET-INSTANCE-PROC-ADDR" :lwlgl.vulkan.vk14))
  (check (%external-function-p "EGL-GET-DISPLAY" :lwlgl.egl.egl15))
  (check (%external-function-p "NEGL-GET-DISPLAY" :lwlgl.egl.egl15))
  (check (%external-function-p "GL-CLEAR" :lwlgl.opengles.gles32))
  (check (%external-function-p "NGL-CLEAR" :lwlgl.opengles.gles32))
  (check (%external-function-p "NGL-CLEAR" :lwlgl.opengl.gl11))
  (check (%external-function-p "NGL-BUFFER-DATA" :lwlgl.opengl.gl15))
  (multiple-value-bind (symbol status) (find-symbol "NGL-BUFFER-DATA" :lwlgl.opengl.gl14)
    (declare (ignore symbol))
    (check (null status)))
  (let* ((pointer (cffi:make-pointer 42))
         (provider (lwlgl.core:make-function-provider
                    :name :fake-gles :resolver (lambda (name)
                                                 (declare (ignore name)) pointer)))
         (capabilities (lwlgl.opengles:create-capabilities :provider provider)))
    (check (lwlgl.opengles:gl-function-available-p "glClear" capabilities))
    (check (= 42 (cffi:pointer-address
                  (lwlgl.core:capability-function-pointer capabilities "glClear"))))
    (check (lwlgl.openal:al-capabilities-p
            (lwlgl.openal:create-capabilities :provider provider)))
    (check (lwlgl.opencl:cl-capabilities-p
            (lwlgl.opencl:create-capabilities :provider provider)))))

(defun test-module-registry ()
  (let ((lwlgl.core:*native-bundle-roots* nil))
    (lwlgl.core:register-native-module :lwlgl-test '("definitely-not-loaded"))
    (check (lwlgl.core:find-native-module :lwlgl-test))
    (check (member :lwlgl-test (mapcar #'lwlgl.core:native-module-name
                                        (lwlgl.core:list-native-modules))))
    (check (equal '("definitely-not-loaded")
                  (lwlgl.core:native-library-candidates :lwlgl-test)))
    (check (search "-" (lwlgl.core:native-platform-triple)))))

(defun test-platform ()
  (check (member (lwlgl.core:platform) '(:windows :macos :linux :unknown)))
  (check (string= "1.0.0" lwlgl.core:*lwlgl-version*)))

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


(defun test-spatial-query ()
  (let* ((ball (lwlgl.math:sphere (lwlgl.math:vec3 0 0 0) 1.0))
         (ray (lwlgl.math:ray (lwlgl.math:vec3 -5 0 0) (lwlgl.math:vec3 1 0 0)))
         (box (lwlgl.math:aabb (lwlgl.math:vec3 -0.5 -0.5 -0.5)
                               (lwlgl.math:vec3 0.5 0.5 0.5))))
    (check (lwlgl.math:sphere-contains-point-p ball (lwlgl.math:vec3 0.5 0 0)))
    (check (lwlgl.math:sphere-intersects-aabb-p ball box))
    (multiple-value-bind (near far) (lwlgl.math:ray-sphere-intersection ray ball)
      (check (approximately= 4.0 near))
      (check (approximately= 6.0 far)))
    (let* ((projection (lwlgl.math:perspective-mat4
                        (lwlgl.math:degrees->radians 90) 1.0 1.0 10.0))
           (frustum (lwlgl.math:frustum-from-matrix projection)))
      (check (lwlgl.math:frustum-contains-point-p frustum (lwlgl.math:vec3 0 0 -5)))
      (check (not (lwlgl.math:frustum-contains-point-p frustum (lwlgl.math:vec3 10 0 -5))))
      (check (lwlgl.math:frustum-intersects-sphere-p
              frustum (lwlgl.math:sphere (lwlgl.math:vec3 0 0 -5) 1.0)))
      (check (lwlgl.math:frustum-intersects-aabb-p
              frustum
              (lwlgl.math:aabb (lwlgl.math:vec3 -1 -1 -6)
                               (lwlgl.math:vec3 1 1 -4)))))))

(defun test-timers ()
  (let ((queue (lwlgl.util:make-timer-queue))
        (once 0)
        (repeated 0))
    (lwlgl.util:schedule-timer queue 0.5d0 (lambda () (incf once)))
    (let ((repeat-id
            (lwlgl.util:schedule-repeating-timer
             queue 0.25d0 (lambda () (incf repeated)))))
      (check (= 3 (lwlgl.util:advance-timers queue 0.5d0)))
      (check (= once 1))
      (check (= repeated 2))
      (check (lwlgl.util:timer-active-p queue repeat-id))
      (lwlgl.util:cancel-timer queue repeat-id)
      (lwlgl.util:advance-timers queue 1.0d0)
      (check (= repeated 2)))))

(defun test-input-composites ()
  (let* ((state (lwlgl.input:make-input-state))
         (map (lwlgl.input:make-action-map))
         (ctrl (lwlgl.input:key-binding lwlgl.glfw:key-left-control))
         (s-key (lwlgl.input:key-binding lwlgl.glfw:key-s)))
    (setf (gethash lwlgl.glfw:key-left-control (lwlgl.input::input-state-keys-down state)) t
          (gethash lwlgl.glfw:key-s (lwlgl.input::input-state-keys-down state)) t
          (gethash lwlgl.glfw:key-s (lwlgl.input::input-state-keys-pressed state)) t)
    (lwlgl.input:bind-action map :save (lwlgl.input:chord-binding ctrl s-key))
    (check (lwlgl.input:action-down-p map state :save))
    (check (lwlgl.input:action-pressed-p map state :save))
    (remhash lwlgl.glfw:key-s (lwlgl.input::input-state-keys-down state))
    (lwlgl.input:bind-axis2
     map :move
     (lwlgl.input:key-binding lwlgl.glfw:key-a)
     (lwlgl.input:key-binding lwlgl.glfw:key-d)
     (lwlgl.input:key-binding lwlgl.glfw:key-s)
     (lwlgl.input:key-binding lwlgl.glfw:key-w)
     :normalize t)
    (setf (gethash lwlgl.glfw:key-d (lwlgl.input::input-state-keys-down state)) t
          (gethash lwlgl.glfw:key-w (lwlgl.input::input-state-keys-down state)) t)
    (multiple-value-bind (x y) (lwlgl.input:axis2-value map state :move)
      (check (approximately= x (/ 1.0 (sqrt 2.0))))
      (check (approximately= y (/ 1.0 (sqrt 2.0)))))))

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
  (let* ((manager (lwlgl.assets:make-asset-manager :roots nil))
         (path (merge-pathnames
                (format nil "lwlgl-test-~D-~D.txt" (get-universal-time) (random 1000000))
                (uiop:temporary-directory)))
         (listener (lambda (manager path value)
                     (declare (ignore manager path value)))))
    (unwind-protect
         (progn
           (with-open-file (stream path :direction :output :if-exists :supersede :if-does-not-exist :create)
             (write-string "hello" stream))
           (lwlgl.assets:register-asset-loader manager "txt" #'lwlgl.assets:load-text-file)
           (check (functionp (lwlgl.assets:asset-loader manager "TXT")))
           (check (= 0 (lwlgl.assets:asset-cache-size manager)))
           (check (equal '("hello") (lwlgl.assets:preload-assets manager (list path))))
           (check (= 1 (lwlgl.assets:asset-cache-size manager)))
           (check (= 1 (length (lwlgl.assets:cached-assets manager))))
           (lwlgl.assets:add-asset-reload-listener manager listener)
           (lwlgl.assets:remove-asset-reload-listener manager listener))
      (ignore-errors (delete-file path)))))

(defun run-tests ()
  (setf *failures* 0 *checks* 0)
  (test-native-buffer)
  (test-native-memory-views-and-arena)
  (test-lwjgl-style-memory)
  (test-runtime-configuration)
  (test-dispatch-runtime)
  (test-binding-generator)
  (test-opengl-binding-metadata)
  (test-lwjgl-api-surface)
  (test-module-registry)
  (test-platform)
  (test-vectors)
  (test-matrices)
  (test-quaternions)
  (test-geometry)
  (test-spatial-query)
  (test-timers)
  (test-input-composites)
  (test-fixed-step)
  (test-profiler)
  (test-obj)
  (test-assets)
  (format t "~&LWLGL tests: ~A checks, ~A failures.~%" *checks* *failures*)
  (when (plusp *failures*) (error "LWLGL tests failed."))
  t)
