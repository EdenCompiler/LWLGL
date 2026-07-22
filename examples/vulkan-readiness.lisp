(in-package #:lwlgl.examples)

(defun vulkan-readiness ()
  "Checks the loader and GLFW requirements needed before creating a Vulkan instance."
  (lwlgl.glfw.glfw34:glfw-with-glfw ()
    (unless (lwlgl.glfw.glfw34:glfw-vulkan-supported-p)
      (error "GLFW cannot find a usable Vulkan loader and ICD."))
    (lwlgl.glfw.glfw34:glfw-default-window-hints)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-client-api+ lwlgl.glfw.glfw34:+glfw-no-api+)
    (lwlgl.glfw.glfw34:glfw-window-hint
     lwlgl.glfw.glfw34:+glfw-visible+ lwlgl.glfw.glfw34:+glfw-false+)
    (lwlgl.glfw.glfw34:glfw-with-window (window 64 64 "LWLGL Vulkan readiness")
      (unless window (error "GLFW did not create the Vulkan window."))
      (unwind-protect
           (let* ((info (lwlgl.vulkan:vulkan-loader-info))
                  (capabilities
                    (lwlgl.vulkan.vk14:create-instance-capabilities))
                  (required
                    (lwlgl.glfw.glfw34:glfw-required-vulkan-instance-extensions))
                  (available
                    (mapcar (lambda (extension) (getf extension :name))
                            (getf info :extensions)))
                  (missing (set-difference required available :test #'string=))
                  (validation-layer
                    (find "VK_LAYER_KHRONOS_validation" (getf info :layers)
                          :test #'string= :key (lambda (layer) (getf layer :name))))
                  (report
                    (list :api-version
                          (list (getf info :major) (getf info :minor) (getf info :patch))
                          :required-window-extensions required
                          :missing-window-extensions missing
                          :enumerate-extensions-command
                          (not (null
                                (lwlgl.core:capability-function-pointer
                                 capabilities
                                 "vkEnumerateInstanceExtensionProperties")))
                          :validation-layer-available (not (null validation-layer)))))
             (format t "~&Vulkan ~{~D~^.~}; GLFW extensions: ~S~%"
                     (getf report :api-version) required)
             (format t "Missing extensions: ~S; validation layer: ~:[no~;yes~]~%"
                     missing (getf report :validation-layer-available))
             (when missing
               (error "The Vulkan loader lacks GLFW-required extensions: ~S" missing))
             report)
        (lwlgl.vulkan:destroy)))))
