(in-package #:lwlgl.input)

(defstruct (action-map (:constructor make-action-map ()))
  (actions (make-hash-table :test #'equal))
  (axes (make-hash-table :test #'equal))
  (axes2 (make-hash-table :test #'equal)))

(defun key-binding (key) (list :key key))
(defun mouse-binding (button) (list :mouse button))

(defun chord-binding (&rest bindings)
  "Creates a composite binding that is active only while every child binding is active."
  (when (endp bindings) (error "CHORD-BINDING requires at least one binding."))
  (list :all bindings))

(defun any-binding (&rest bindings)
  "Creates a composite binding that is active while any child binding is active."
  (when (endp bindings) (error "ANY-BINDING requires at least one binding."))
  (list :any bindings))

(defun bind-action (map name binding &rest more-bindings)
  "Binds NAME to one or more key, mouse or composite descriptors. Existing bindings are replaced."
  (setf (gethash name (action-map-actions map)) (cons binding more-bindings))
  map)

(defun add-action-binding (map name binding)
  (pushnew binding (gethash name (action-map-actions map)) :test #'equal)
  map)

(defun unbind-action (map name)
  (remhash name (action-map-actions map))
  map)

(defun action-bindings (map name)
  (copy-tree (gethash name (action-map-actions map))))

(defun %binding-state (state binding kind)
  (let ((type (first binding))
        (payload (second binding)))
    (ecase type
      (:key (ecase kind
              (:down (key-down-p state payload))
              (:pressed (key-pressed-p state payload))
              (:released (key-released-p state payload))))
      (:mouse (ecase kind
                (:down (mouse-down-p state payload))
                (:pressed (mouse-pressed-p state payload))
                (:released (mouse-released-p state payload))))
      (:any (some (lambda (child) (%binding-state state child kind)) payload))
      (:all
       (ecase kind
         (:down (every (lambda (child) (%binding-state state child :down)) payload))
         (:pressed (and (every (lambda (child) (%binding-state state child :down)) payload)
                        (some (lambda (child) (%binding-state state child :pressed)) payload)))
         (:released (some (lambda (child) (%binding-state state child :released)) payload)))))))

(defun %action-state (map state name kind)
  (some (lambda (binding) (%binding-state state binding kind))
        (gethash name (action-map-actions map))))

(defun action-down-p (map state name) (%action-state map state name :down))
(defun action-pressed-p (map state name) (%action-state map state name :pressed))
(defun action-released-p (map state name) (%action-state map state name :released))

(defun %binding-list (binding-or-bindings)
  (if (and (consp binding-or-bindings) (keywordp (first binding-or-bindings)))
      (list binding-or-bindings)
      binding-or-bindings))

(defun bind-axis (map name negative-binding positive-binding &key (scale 1.0))
  "Defines a digital axis. Each side may be a binding descriptor or a list of descriptors."
  (setf (gethash name (action-map-axes map))
        (list :negative (%binding-list negative-binding)
              :positive (%binding-list positive-binding)
              :scale (coerce scale 'single-float)))
  map)

(defun unbind-axis (map name) (remhash name (action-map-axes map)) map)

(defun %axis-definition-value (definition state)
  (if (null definition) 0.0f0
      (let* ((negative (some (lambda (binding) (%binding-state state binding :down)) (getf definition :negative)))
             (positive (some (lambda (binding) (%binding-state state binding :down)) (getf definition :positive)))
             (scale (getf definition :scale)))
        (* scale (+ (if positive 1.0f0 0.0f0) (if negative -1.0f0 0.0f0))))))

(defun axis-value (map state name)
  "Returns a digital axis in [-SCALE,+SCALE], with opposite directions cancelling."
  (%axis-definition-value (gethash name (action-map-axes map)) state))

(defun bind-axis2 (map name left-binding right-binding down-binding up-binding &key (scale 1.0) normalize)
  "Defines a two-dimensional digital axis. AXIS2-VALUE returns X and Y as two values."
  (setf (gethash name (action-map-axes2 map))
        (list :left (%binding-list left-binding)
              :right (%binding-list right-binding)
              :down (%binding-list down-binding)
              :up (%binding-list up-binding)
              :scale (coerce scale 'single-float)
              :normalize (not (null normalize))))
  map)

(defun unbind-axis2 (map name)
  (remhash name (action-map-axes2 map))
  map)

(defun axis2-value (map state name)
  "Returns X and Y for a named two-dimensional digital axis as two values."
  (let ((definition (gethash name (action-map-axes2 map))))
    (if (null definition)
        (values 0.0f0 0.0f0)
        (flet ((active (key)
                 (some (lambda (binding) (%binding-state state binding :down))
                       (getf definition key))))
          (let* ((scale (getf definition :scale))
                 (x (* scale (+ (if (active :right) 1.0f0 0.0f0)
                                (if (active :left) -1.0f0 0.0f0))))
                 (y (* scale (+ (if (active :up) 1.0f0 0.0f0)
                                (if (active :down) -1.0f0 0.0f0)))))
            (if (and (getf definition :normalize) (not (zerop x)) (not (zerop y)))
                (let ((factor (/ 1.0f0 (sqrt 2.0f0))))
                  (values (* x factor) (* y factor)))
                (values x y)))))))

(defun action-map-names (map)
  (loop for name being the hash-keys of (action-map-actions map) collect name))

(defun axis-map-names (map)
  (loop for name being the hash-keys of (action-map-axes map) collect name))

(defun axis2-map-names (map)
  (loop for name being the hash-keys of (action-map-axes2 map) collect name))
