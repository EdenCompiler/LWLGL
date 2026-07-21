(in-package #:lwlgl.math)

(defstruct (plane (:constructor %make-plane (normal distance)))
  normal
  (distance 0.0f0 :type single-float))

(defun plane (normal distance &key (normalize t))
  "Creates a plane using the equation DOT(NORMAL, POINT) + DISTANCE = 0."
  (check-type normal vec3)
  (let ((length (vec-length normal)))
    (when (and normalize (<= length 1.0e-7))
      (error "Cannot normalize a plane with a zero-length normal."))
    (if normalize
        (%make-plane (vec-scale normal (/ 1.0 length)) (%sf (/ distance length)))
        (%make-plane normal (%sf distance)))))

(defun plane-distance-to-point (plane point)
  "Returns the signed distance from POINT to PLANE when the plane is normalized."
  (check-type plane plane)
  (check-type point vec3)
  (+ (vec-dot (plane-normal plane) point) (plane-distance plane)))

(defstruct (sphere (:constructor %make-sphere (center radius)))
  center
  (radius 0.0f0 :type single-float))

(defun sphere (center radius)
  (check-type center vec3)
  (when (< radius 0) (error "Sphere radius must be non-negative."))
  (%make-sphere center (%sf radius)))

(defun sphere-contains-point-p (sphere point)
  (<= (vec-distance (sphere-center sphere) point) (sphere-radius sphere)))

(defun sphere-intersects-sphere-p (a b)
  (<= (vec-distance (sphere-center a) (sphere-center b))
      (+ (sphere-radius a) (sphere-radius b))))

(defun sphere-intersects-aabb-p (sphere box)
  "Returns true when SPHERE overlaps BOX."
  (let* ((center (sphere-center sphere))
         (minimum (aabb-min box))
         (maximum (aabb-max box))
         (x (max (vec3-x minimum) (min (vec3-x center) (vec3-x maximum))))
         (y (max (vec3-y minimum) (min (vec3-y center) (vec3-y maximum))))
         (z (max (vec3-z minimum) (min (vec3-z center) (vec3-z maximum))))
         (closest (vec3 x y z)))
    (<= (vec-length-squared (vec-sub center closest))
        (* (sphere-radius sphere) (sphere-radius sphere)))))

(defun ray-sphere-intersection (ray sphere &key (minimum-distance 0.0) (maximum-distance most-positive-single-float))
  "Returns entry and exit distances as two values, or NIL when RAY misses SPHERE."
  (let* ((origin-to-center (vec-sub (ray-origin ray) (sphere-center sphere)))
         (direction (ray-direction ray))
         (a (vec-dot direction direction))
         (b (* 2.0f0 (vec-dot origin-to-center direction)))
         (c (- (vec-dot origin-to-center origin-to-center)
               (* (sphere-radius sphere) (sphere-radius sphere))))
         (discriminant (- (* b b) (* 4.0f0 a c))))
    (when (<= a 1.0e-12)
      (return-from ray-sphere-intersection nil))
    (when (minusp discriminant)
      (return-from ray-sphere-intersection nil))
    (let* ((root (sqrt discriminant))
           (denominator (* 2.0f0 a))
           (near (/ (- (- b) root) denominator))
           (far (/ (+ (- b) root) denominator))
           (entry (max near (coerce minimum-distance 'single-float)))
           (exit (min far (coerce maximum-distance 'single-float))))
      (when (<= entry exit)
        (values entry exit)))))

(defstruct (frustum (:constructor %make-frustum (planes)))
  planes)

(defun %plane-from-coefficients (a b c d)
  (plane (vec3 a b c) d))

(defun frustum-from-matrix (clip-matrix)
  "Extracts the six inward-facing clipping planes from an OpenGL-style clip matrix."
  (check-type clip-matrix mat4)
  (labels ((coefficient (row column)
           (mat4-ref clip-matrix row column))
         (make-extracted-plane (row-sign row-index)
           (%plane-from-coefficients
            (+ (coefficient 3 0) (* row-sign (coefficient row-index 0)))
            (+ (coefficient 3 1) (* row-sign (coefficient row-index 1)))
            (+ (coefficient 3 2) (* row-sign (coefficient row-index 2)))
            (+ (coefficient 3 3) (* row-sign (coefficient row-index 3))))))
    (%make-frustum
     (vector (make-extracted-plane 1.0f0 0)   ; left
             (make-extracted-plane -1.0f0 0)  ; right
             (make-extracted-plane 1.0f0 1)   ; bottom
             (make-extracted-plane -1.0f0 1)  ; top
             (make-extracted-plane 1.0f0 2)   ; near
             (make-extracted-plane -1.0f0 2))))) ; far

(defun frustum-contains-point-p (frustum point)
  (check-type frustum frustum)
  (check-type point vec3)
  (every (lambda (plane) (>= (plane-distance-to-point plane point) 0.0f0))
         (frustum-planes frustum)))

(defun frustum-intersects-sphere-p (frustum sphere)
  (check-type frustum frustum)
  (check-type sphere sphere)
  (every (lambda (plane)
           (>= (plane-distance-to-point plane (sphere-center sphere))
               (- (sphere-radius sphere))))
         (frustum-planes frustum)))

(defun frustum-intersects-aabb-p (frustum box)
  "Uses the positive-vertex plane test to reject AABBs fully outside FRUSTUM."
  (check-type frustum frustum)
  (check-type box aabb)
  (let ((minimum (aabb-min box))
        (maximum (aabb-max box)))
    (every
     (lambda (plane)
       (let ((normal (plane-normal plane)))
         (>= (plane-distance-to-point
              plane
              (vec3 (if (>= (vec3-x normal) 0.0f0) (vec3-x maximum) (vec3-x minimum))
                    (if (>= (vec3-y normal) 0.0f0) (vec3-y maximum) (vec3-y minimum))
                    (if (>= (vec3-z normal) 0.0f0) (vec3-z maximum) (vec3-z minimum))))
             0.0f0)))
     (frustum-planes frustum))))
