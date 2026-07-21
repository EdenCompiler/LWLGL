(in-package #:lwlgl.math)

(declaim (inline %sf))
(defun %sf (value) (coerce value 'single-float))

(defstruct (vec2 (:constructor %make-vec2 (x y)))
  (x 0.0f0 :type single-float)
  (y 0.0f0 :type single-float))

(defstruct (vec3 (:constructor %make-vec3 (x y z)))
  (x 0.0f0 :type single-float)
  (y 0.0f0 :type single-float)
  (z 0.0f0 :type single-float))

(defstruct (vec4 (:constructor %make-vec4 (x y z w)))
  (x 0.0f0 :type single-float)
  (y 0.0f0 :type single-float)
  (z 0.0f0 :type single-float)
  (w 0.0f0 :type single-float))

(defun vec2 (&optional (x 0.0) (y 0.0))
  (%make-vec2 (%sf x) (%sf y)))

(defun vec3 (&optional (x 0.0) (y 0.0) (z 0.0))
  (%make-vec3 (%sf x) (%sf y) (%sf z)))

(defun vec4 (&optional (x 0.0) (y 0.0) (z 0.0) (w 0.0))
  (%make-vec4 (%sf x) (%sf y) (%sf z) (%sf w)))

(defun vec-add (a b)
  (etypecase a
    (vec2 (check-type b vec2)
          (vec2 (+ (vec2-x a) (vec2-x b)) (+ (vec2-y a) (vec2-y b))))
    (vec3 (check-type b vec3)
          (vec3 (+ (vec3-x a) (vec3-x b)) (+ (vec3-y a) (vec3-y b)) (+ (vec3-z a) (vec3-z b))))
    (vec4 (check-type b vec4)
          (vec4 (+ (vec4-x a) (vec4-x b)) (+ (vec4-y a) (vec4-y b))
                (+ (vec4-z a) (vec4-z b)) (+ (vec4-w a) (vec4-w b))))))

(defun vec-sub (a b)
  (etypecase a
    (vec2 (check-type b vec2)
          (vec2 (- (vec2-x a) (vec2-x b)) (- (vec2-y a) (vec2-y b))))
    (vec3 (check-type b vec3)
          (vec3 (- (vec3-x a) (vec3-x b)) (- (vec3-y a) (vec3-y b)) (- (vec3-z a) (vec3-z b))))
    (vec4 (check-type b vec4)
          (vec4 (- (vec4-x a) (vec4-x b)) (- (vec4-y a) (vec4-y b))
                (- (vec4-z a) (vec4-z b)) (- (vec4-w a) (vec4-w b))))))

(defun vec-scale (vector scalar)
  (let ((s (%sf scalar)))
    (etypecase vector
      (vec2 (vec2 (* (vec2-x vector) s) (* (vec2-y vector) s)))
      (vec3 (vec3 (* (vec3-x vector) s) (* (vec3-y vector) s) (* (vec3-z vector) s)))
      (vec4 (vec4 (* (vec4-x vector) s) (* (vec4-y vector) s)
                  (* (vec4-z vector) s) (* (vec4-w vector) s))))))

(defun vec-hadamard (a b)
  (etypecase a
    (vec2 (check-type b vec2)
          (vec2 (* (vec2-x a) (vec2-x b)) (* (vec2-y a) (vec2-y b))))
    (vec3 (check-type b vec3)
          (vec3 (* (vec3-x a) (vec3-x b)) (* (vec3-y a) (vec3-y b)) (* (vec3-z a) (vec3-z b))))
    (vec4 (check-type b vec4)
          (vec4 (* (vec4-x a) (vec4-x b)) (* (vec4-y a) (vec4-y b))
                (* (vec4-z a) (vec4-z b)) (* (vec4-w a) (vec4-w b))))))

(defun vec-dot (a b)
  (etypecase a
    (vec2 (check-type b vec2)
          (+ (* (vec2-x a) (vec2-x b)) (* (vec2-y a) (vec2-y b))))
    (vec3 (check-type b vec3)
          (+ (* (vec3-x a) (vec3-x b)) (* (vec3-y a) (vec3-y b)) (* (vec3-z a) (vec3-z b))))
    (vec4 (check-type b vec4)
          (+ (* (vec4-x a) (vec4-x b)) (* (vec4-y a) (vec4-y b))
             (* (vec4-z a) (vec4-z b)) (* (vec4-w a) (vec4-w b))))))

(defun vec-cross (a b)
  (check-type a vec3)
  (check-type b vec3)
  (vec3 (- (* (vec3-y a) (vec3-z b)) (* (vec3-z a) (vec3-y b)))
        (- (* (vec3-z a) (vec3-x b)) (* (vec3-x a) (vec3-z b)))
        (- (* (vec3-x a) (vec3-y b)) (* (vec3-y a) (vec3-x b)))))

(defun vec-length-squared (vector)
  (vec-dot vector vector))

(defun vec-length (vector)
  (sqrt (vec-length-squared vector)))

(defun vec-normalize (vector &key (epsilon 1.0e-7))
  (let ((length (vec-length vector)))
    (if (<= length epsilon)
        (etypecase vector
          (vec2 (vec2)) (vec3 (vec3)) (vec4 (vec4)))
        (vec-scale vector (/ 1.0 length)))))

(defun vec-distance (a b)
  (vec-length (vec-sub a b)))

(defun vec-lerp (a b amount)
  (vec-add a (vec-scale (vec-sub b a) amount)))
