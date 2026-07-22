(in-package #:lwlgl.vulkan)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter +vk-version-package-names+
    '("LWLGL.VULKAN.VK10" "LWLGL.VULKAN.VK11" "LWLGL.VULKAN.VK12"
      "LWLGL.VULKAN.VK13" "LWLGL.VULKAN.VK14"))
  (dolist (name +vk-version-package-names+)
    (unless (find-package name) (make-package name :use '(#:cl))))
  (labels ((reexport (from to)
             (do-external-symbols (symbol from)
               (shadowing-import symbol to)
               (export symbol to))))
    (let ((base (find-package "LWLGL.VULKAN.VK10")))
      (do-external-symbols (symbol '#:lwlgl.vulkan)
        (shadowing-import symbol base)
        (export symbol base)))
    (loop for (older newer) on +vk-version-package-names+
          while newer
          when older do (reexport (find-package older) (find-package newer)))))
