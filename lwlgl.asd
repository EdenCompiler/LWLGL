(asdf:defsystem #:lwlgl/core
  :description "LWLGL core: native modules, memory utilities and diagnostics."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:cffi #:uiop)
  :serial t
  :components ((:file "src/core/package")
               (:file "src/core/platform")
               (:file "src/core/conditions")
               (:file "src/core/config")
               (:file "src/core/modules")
               (:file "src/core/memory")
               (:file "src/core/dispatch")
               (:file "src/core/runtime")))

(asdf:defsystem #:lwlgl/bindgen
  :description "Deterministic declarative binding generator for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:uiop)
  :serial t
  :components ((:file "src/generator/package")
               (:file "src/generator/generator")))

(asdf:defsystem #:lwlgl/math
  :description "Allocation-conscious vectors, matrices, quaternions, geometry queries and frustum-culling helpers for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :serial t
  :components ((:file "src/math/package")
               (:file "src/math/vectors")
               (:file "src/math/matrices")
               (:file "src/math/quaternions")
               (:file "src/math/geometry")
               (:file "src/math/spatial")))

(asdf:defsystem #:lwlgl/util
  :description "Timing, fixed-step simulation, deterministic timers and lightweight profiling for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core)
  :serial t
  :components ((:file "src/util/package")
               (:file "src/util/timing")
               (:file "src/util/timers")
               (:file "src/util/profiling")))

(asdf:defsystem #:lwlgl/glfw
  :description "GLFW bindings and idiomatic Common Lisp window/input helpers."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:cffi)
  :serial t
  :components ((:file "src/glfw/package")
               (:file "src/glfw/raw")
               (:file "src/glfw/devices")
               (:file "src/glfw/window")
               (:file "src/glfw/versions")))

(asdf:defsystem #:lwlgl/input
  :description "Stateful keyboard/mouse input, composite bindings and named 1D/2D action maps built on LWLGL GLFW callbacks."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/glfw)
  :serial t
  :components ((:file "src/input/package")
               (:file "src/input/state")
               (:file "src/input/actions")))

(asdf:defsystem #:lwlgl/assets
  :description "Search paths, cached/bulk asset loading, cache inspection and hot-reload notifications for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:uiop)
  :serial t
  :components ((:file "src/assets/package")
               (:file "src/assets/assets")))

(asdf:defsystem #:lwlgl/obj
  :description "Dependency-free Wavefront OBJ parser producing indexed GPU-ready vertex streams."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/math #:uiop)
  :serial t
  :components ((:file "src/obj/package")
               (:file "src/obj/obj")))

(asdf:defsystem #:lwlgl/opengl
  :description "Runtime-loaded OpenGL bindings for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:lwlgl/glfw #:lwlgl/math #:cffi)
  :serial t
  :components ((:file "src/opengl/package")
               (:file "src/opengl/constants")
               (:file "src/opengl/loader")
               (:file "src/opengl/functions")
               (:file "src/opengl/helpers")
               (:file "src/opengl/versions")))

(asdf:defsystem #:lwlgl/egl
  :description "Runtime-loaded EGL 1.5 bindings for LWLGL."
  :author "Bruno" :license "MIT" :version "1.0.0"
  :depends-on (#:lwlgl/core #:cffi)
  :serial t
  :components ((:file "src/egl/package")
               (:file "src/egl/egl")))

(asdf:defsystem #:lwlgl/opengles
  :description "Capability-dispatched OpenGL ES bindings for LWLGL."
  :author "Bruno" :license "MIT" :version "1.0.0"
  :depends-on (#:lwlgl/core #:lwlgl/egl #:cffi)
  :serial t
  :components ((:file "src/opengles/package")
               (:file "src/opengles/gles")))

(asdf:defsystem #:lwlgl/openal
  :description "OpenAL/ALC bindings, device discovery, capture, WAV loading and streaming helpers for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:cffi)
  :serial t
  :components ((:file "src/openal/package")
               (:file "src/openal/raw")
               (:file "src/openal/audio")
               (:file "src/openal/wav")
               (:file "src/openal/versions")))

(asdf:defsystem #:lwlgl/vulkan
  :description "Vulkan loader and bootstrap introspection for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:cffi)
  :serial t
  :components ((:file "src/vulkan/package")
               (:file "src/vulkan/loader")
               (:file "src/vulkan/versions")))

(asdf:defsystem #:lwlgl/opencl
  :description "OpenCL platform/device discovery bindings for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:cffi)
  :serial t
  :components ((:file "src/opencl/package")
               (:file "src/opencl/raw")
               (:file "src/opencl/discovery")
               (:file "src/opencl/versions")))

(asdf:defsystem #:lwlgl/stb
  :description "stb_image bindings through the bundled LWLGL native shim."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:cffi)
  :serial t
  :components ((:file "src/stb/package")
               (:file "src/stb/image")))

(asdf:defsystem #:lwlgl/gfx
  :description "OpenGL integration helpers: shader includes, image textures and OBJ GPU meshes."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/opengl #:lwlgl/stb #:lwlgl/obj #:cffi #:uiop)
  :serial t
  :components ((:file "src/gfx/package")
               (:file "src/gfx/gfx")))

(asdf:defsystem #:lwlgl/bindings
  :description "LWLGL low-level native runtime and independently usable bindings."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:lwlgl/glfw #:lwlgl/opengl #:lwlgl/egl #:lwlgl/opengles #:lwlgl/openal
               #:lwlgl/vulkan #:lwlgl/opencl #:lwlgl/stb)
  :components ())

(asdf:defsystem #:lwlgl/extras
  :description "Optional Lisp-native utilities and integration helpers for LWLGL."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/math #:lwlgl/util #:lwlgl/input #:lwlgl/assets
               #:lwlgl/obj #:lwlgl/gfx)
  :components ())

(asdf:defsystem #:lwlgl/all
  :description "All LWLGL bindings, generator infrastructure, and optional utilities."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/bindings #:lwlgl/extras #:lwlgl/bindgen)
  :components ())

(asdf:defsystem #:lwlgl
  :description "Compatibility umbrella for LWLGL 1.0; equivalent to lwlgl/all."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/all)
  :components ())

(asdf:defsystem #:lwlgl/examples
  :description "Runnable LWLGL examples."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/all)
  :serial t
  :components ((:file "examples/package")
               (:file "examples/hello-window")
               (:file "examples/triangle")
               (:file "examples/spinning-cube")
               (:file "examples/textured-quad")
               (:file "examples/offscreen-framebuffer")
               (:file "examples/instanced-triangles")
               (:file "examples/input-demo")
               (:file "examples/audio-tone")
               (:file "examples/positional-audio")
               (:file "examples/system-info")
               (:file "examples/vulkan-readiness")
               (:file "examples/toolbox-demo")
               (:file "examples/native-memory")
               (:file "examples/capabilities-demo")
               (:file "examples/opengl-info")
               (:file "examples/egl-info")))

(asdf:defsystem #:lwlgl/tests
  :description "LWLGL tests that do not require a graphics/audio device."
  :author "Bruno"
  :license "MIT"
  :version "1.0.0"
  :depends-on (#:lwlgl/core #:lwlgl/math #:lwlgl/util #:lwlgl/input #:lwlgl/assets #:lwlgl/obj
               #:lwlgl/opengl #:lwlgl/egl #:lwlgl/opengles #:lwlgl/openal
               #:lwlgl/opencl #:lwlgl/vulkan #:lwlgl/bindgen)
  :serial t
  :components ((:file "tests/package")
               (:file "tests/tests"))
  :perform (asdf:test-op (o c)
             (declare (ignore o c))
             (uiop:symbol-call "LWLGL.TESTS" "RUN-TESTS")))
