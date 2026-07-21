(in-package #:lwlgl.input)

(defstruct (action-map (:constructor make-action-map ()))
  (actions (make-hash-table :test #'equal))
  (axes (make-hash-table :test #'equal)))

(defun key-binding (key) (list :key key))
(defun mouse-binding (button) (list :mouse button))

(defun bind-action (map name binding &rest more-bindings)
  "Binds NAME to one or more (:KEY code) / (:MOUSE button) descriptors. Existing bindings are replaced."
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
  (destructuring-bind (type code) binding
    (ecase type
      (:key (ecase kind
              (:down (key-down-p state code))
              (:pressed (key-pressed-p state code))
              (:released (key-released-p state code))))
      (:mouse (ecase kind
                (:down (mouse-down-p state code))
                (:pressed (mouse-pressed-p state code))
                (:released (mouse-released-p state code)))))))

(defun %action-state (map state name kind)
  (some (lambda (binding) (%binding-state state binding kind))
        (gethash name (action-map-actions map))))

(defun action-down-p (map state name) (%action-state map state name :down))
(defun action-pressed-p (map state name) (%action-state map state name :pressed))
(defun action-released-p (map state name) (%action-state map state name :released))

(defun bind-axis (map name negative-binding positive-binding &key (scale 1.0))
  "Defines a digital axis. Negative and positive bindings may each be a key/mouse descriptor or a list of descriptors."
  (setf (gethash name (action-map-axes map))
        (list :negative (if (and (consp negative-binding) (keywordp (first negative-binding)))
                            (list negative-binding) negative-binding)
              :positive (if (and (consp positive-binding) (keywordp (first positive-binding)))
                            (list positive-binding) positive-binding)
              :scale (coerce scale 'single-float)))
  map)

(defun unbind-axis (map name) (remhash name (action-map-axes map)) map)

(defun axis-value (map state name)
  "Returns a digital axis in [-SCALE,+SCALE], with opposite directions cancelling."
  (let ((definition (gethash name (action-map-axes map))))
    (if (null definition) 0.0f0
        (let* ((negative (some (lambda (binding) (%binding-state state binding :down)) (getf definition :negative)))
               (positive (some (lambda (binding) (%binding-state state binding :down)) (getf definition :positive)))
               (scale (getf definition :scale)))
          (* scale (+ (if positive 1.0f0 0.0f0) (if negative -1.0f0 0.0f0)))))))

(defun action-map-names (map)
  (loop for name being the hash-keys of (action-map-actions map) collect name))

(defun axis-map-names (map)
  (loop for name being the hash-keys of (action-map-axes map) collect name))
