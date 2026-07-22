(in-package #:lwlgl.examples)

(defun %external-function-present-p (package name)
  (multiple-value-bind (symbol status) (find-symbol name package)
    (and (eq status :external) (not (null (fboundp symbol))))))

(defun capabilities-demo ()
  "Builds device-free capability tables and inspects the versioned API surface."
  (let* ((address (cffi:make-pointer #x1000))
         (provider
           (lwlgl.core:make-function-provider
            :name :example-provider
            :resolver (lambda (name)
                        (declare (ignore name))
                        address)))
         (gles (lwlgl.opengles:create-capabilities :provider provider))
         (openal (lwlgl.openal:create-capabilities :provider provider))
         (opencl (lwlgl.opencl:create-capabilities :provider provider))
         (surface
           (list
            :gl33-checked (%external-function-present-p
                           :lwlgl.opengl.gl33 "GL-DRAW-ARRAYS-INSTANCED")
            :gl33-raw (%external-function-present-p
                       :lwlgl.opengl.gl33 "NGL-DRAW-ARRAYS-INSTANCED")
            :glfw34-checked (%external-function-present-p
                             :lwlgl.glfw.glfw34 "GLFW-CREATE-WINDOW")
            :glfw34-raw (%external-function-present-p
                         :lwlgl.glfw.glfw34 "NGLFW-CREATE-WINDOW"))))
    (format t "~&Versioned surface: ~S~%" surface)
    (format t "Capability pointer: #x~X~%"
            (cffi:pointer-address
             (lwlgl.core:capability-function-pointer gles "glClear")))
    (list :surface surface
          :gles (lwlgl.opengles:gles-capabilities-p gles)
          :openal (lwlgl.openal:al-capabilities-p openal)
          :opencl (lwlgl.opencl:cl-capabilities-p opencl))))
