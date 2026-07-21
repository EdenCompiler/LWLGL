(in-package #:lwlgl.assets)

(define-condition asset-error (error) ())
(define-condition asset-not-found (asset-error)
  ((request :initarg :request :reader asset-not-found-request))
  (:report (lambda (condition stream)
             (format stream "Asset not found: ~A" (asset-not-found-request condition)))))

(defstruct asset-entry
  path loader value write-date)

(defstruct (asset-manager (:constructor %make-asset-manager))
  (roots '())
  (loaders (make-hash-table :test #'equalp))
  (cache (make-hash-table :test #'equal)))

(defun make-asset-manager (&key (roots (list #P"./")))
  (let ((manager (%make-asset-manager)))
    (dolist (root roots) (add-asset-root manager root))
    manager))

(defun %directory-pathname (path)
  (uiop:ensure-directory-pathname (pathname path)))

(defun add-asset-root (manager root &key (front nil))
  (let ((directory (%directory-pathname root)))
    (setf (asset-manager-roots manager)
          (if front
              (cons directory (remove directory (asset-manager-roots manager) :test #'equal))
              (append (remove directory (asset-manager-roots manager) :test #'equal) (list directory)))))
  manager)

(defun remove-asset-root (manager root)
  (setf (asset-manager-roots manager)
        (remove (%directory-pathname root) (asset-manager-roots manager) :test #'equal))
  manager)

(defun resolve-asset (manager request &key (errorp t))
  "Resolves REQUEST directly or relative to each asset root. Returns a truename when found."
  (let* ((request-path (pathname request))
         (direct (probe-file request-path)))
    (or direct
        (loop for root in (asset-manager-roots manager)
              for candidate = (probe-file (merge-pathnames request-path root))
              when candidate return candidate)
        (when errorp (error 'asset-not-found :request request)))))

(defun load-text-file (path)
  (uiop:read-file-string path))

(defun load-binary-file (path)
  (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
    (let* ((length (file-length stream))
           (data (make-array length :element-type '(unsigned-byte 8))))
      (read-sequence data stream)
      data)))

(defun %extension-key (extension)
  (string-downcase (string-left-trim "." (string extension))))

(defun register-asset-loader (manager extension function)
  (setf (gethash (%extension-key extension) (asset-manager-loaders manager)) function)
  manager)

(defun unregister-asset-loader (manager extension)
  (remhash (%extension-key extension) (asset-manager-loaders manager))
  manager)

(defun asset-loader (manager extension)
  (gethash (%extension-key extension) (asset-manager-loaders manager)))

(defun %loader-for (manager path explicit-loader)
  (or explicit-loader
      (asset-loader manager (or (pathname-type path) ""))
      (error "No asset loader registered for ~A. Supply :LOADER or REGISTER-ASSET-LOADER." path)))

(defun %cache-key (path loader)
  (list (namestring (truename path)) loader))

(defun load-asset (manager request &key loader (reload-if-changed t))
  "Loads and caches REQUEST. LOADER is called with the resolved pathname. Cached entries are refreshed when the file write date changes."
  (let* ((path (resolve-asset manager request))
         (function (%loader-for manager path loader))
         (key (%cache-key path function))
         (write-date (file-write-date path))
         (entry (gethash key (asset-manager-cache manager))))
    (when (and entry (or (not reload-if-changed) (eql write-date (asset-entry-write-date entry))))
      (return-from load-asset (asset-entry-value entry)))
    (let ((value (funcall function path)))
      (setf (gethash key (asset-manager-cache manager))
            (make-asset-entry :path path :loader function :value value :write-date write-date))
      value)))

(defun cached-asset-p (manager request &key loader)
  (let ((path (resolve-asset manager request :errorp nil)))
    (and path
         (let ((function (and (or loader (pathname-type path))
                              (ignore-errors (%loader-for manager path loader)))))
           (and function (not (null (gethash (%cache-key path function) (asset-manager-cache manager)))))))))

(defun asset-cache-size (manager) (hash-table-count (asset-manager-cache manager)))

(defun invalidate-asset (manager request)
  (let ((path (resolve-asset manager request :errorp nil)))
    (when path
      (let ((name (namestring (truename path)))
            (keys '()))
        (maphash (lambda (key entry)
                   (declare (ignore entry))
                   (when (string= name (first key)) (push key keys)))
                 (asset-manager-cache manager))
        (dolist (key keys) (remhash key (asset-manager-cache manager))))))
  manager)

(defun clear-asset-cache (manager)
  (clrhash (asset-manager-cache manager))
  manager)

(defun reload-changed-assets (manager)
  "Reloads cached entries whose backing file changed. Returns a list of resolved pathnames reloaded."
  (let ((changed '()))
    (maphash
     (lambda (key entry)
       (declare (ignore key))
       (let ((date (ignore-errors (file-write-date (asset-entry-path entry)))))
         (when (and date (not (eql date (asset-entry-write-date entry))))
           (setf (asset-entry-value entry) (funcall (asset-entry-loader entry) (asset-entry-path entry))
                 (asset-entry-write-date entry) date)
           (push (asset-entry-path entry) changed))))
     (asset-manager-cache manager))
    (nreverse changed)))
