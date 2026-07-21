(in-package #:lwlgl.examples)

(defun system-info ()
  "Prints LWLGL runtime, GLFW monitor data, Vulkan loader info and OpenCL devices."
  (lwlgl.core:print-runtime-report)
  (format t "~&GLFW: ")
  (handler-case
      (lwlgl.glfw:with-glfw ()
        (format t "~A~%" (lwlgl.glfw:version-string))
        (let ((monitors (lwlgl.glfw:get-monitors)))
          (format t "Monitors: ~D~%" (length monitors))
          (dolist (monitor monitors)
            (let ((mode (lwlgl.glfw:monitor-video-mode monitor)))
              (if mode
                  (format t "  ~A — ~Dx~D @ ~D Hz~%"
                          (lwlgl.glfw:monitor-name monitor)
                          (lwlgl.glfw:video-mode-width mode)
                          (lwlgl.glfw:video-mode-height mode)
                          (lwlgl.glfw:video-mode-refresh-rate mode))
                  (format t "  ~A~%" (lwlgl.glfw:monitor-name monitor)))))))
    (error (condition) (format t "unavailable (~A)~%" condition)))

  (format t "~&Vulkan: ")
  (if (lwlgl.vulkan:vulkan-supported-p)
      (handler-case
          (let ((info (lwlgl.vulkan:vulkan-loader-info)))
            (format t "~D.~D.~D, ~D instance extensions, ~D layers~%"
                    (getf info :major) (getf info :minor) (getf info :patch)
                    (length (getf info :extensions)) (length (getf info :layers))))
        (error (condition) (format t "loader found but enumeration failed (~A)~%" condition)))
      (format t "unavailable~%"))

  (format t "OpenCL: ")
  (handler-case
      (let ((report (lwlgl.opencl:opencl-report)))
        (format t "~D platform(s)~%" (length report))
        (dolist (platform report)
          (format t "  ~A — ~A~%" (getf platform :name) (getf platform :version))
          (dolist (device (getf platform :devices))
            (format t "    ~A | ~D CU | ~D MiB global memory~%"
                    (getf device :name) (getf device :compute-units)
                    (round (/ (getf device :global-memory-bytes) 1048576))))))
    (error (condition) (format t "unavailable (~A)~%" condition)))
  (values))
