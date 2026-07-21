# LWLGL 0.4 API Guide

This guide highlights the convenience layer. Raw/native-style functions remain available in the module packages.

## Core and diagnostics

```lisp
(lwlgl.core:add-native-search-path #P"./native/")
(lwlgl.core:print-runtime-report)

(lwlgl.core:with-native-buffer (buffer :float 4 :initial-element 0.0)
  (setf (lwlgl.core:buffer-ref buffer 0) 1.0))
```

## Math

```lisp
(let* ((eye (lwlgl.math:vec3 0 1 4))
       (view (lwlgl.math:look-at-mat4 eye
                                      (lwlgl.math:vec3 0 0 0)
                                      (lwlgl.math:vec3 0 1 0)))
       (projection (lwlgl.math:perspective-mat4
                    (lwlgl.math:degrees->radians 60)
                    (/ 16.0 9.0) 0.1 100.0)))
  (lwlgl.math:mat4-mul projection view))
```

Matrices are 16-element single-float column-major arrays.

## Timing

```lisp
(let ((clock (lwlgl.util:make-frame-clock))
      (stepper (lwlgl.util:make-fixed-step :hz 60.0d0)))
  (multiple-value-bind (dt elapsed fps)
      (lwlgl.util:tick-frame-clock clock)
    (declare (ignore elapsed fps))
    (lwlgl.util:advance-fixed-step
     stepper dt
     (lambda (fixed-dt) (update-world fixed-dt)))))
```

### Deterministic timers

```lisp
(let ((timers (lwlgl.util:make-timer-queue :max-catch-up 4)))
  (lwlgl.util:schedule-timer timers 1.0d0 #'show-message)
  (defparameter *spawn-timer*
    (lwlgl.util:schedule-repeating-timer timers 0.25d0 #'spawn-particle))

  ;; Advance using your frame delta.
  (lwlgl.util:advance-timers timers dt)
  (lwlgl.util:pause-timer timers *spawn-timer*)
  (lwlgl.util:resume-timer timers *spawn-timer*)
  (lwlgl.util:cancel-timer timers *spawn-timer*))
```

`TIMER-QUEUE-TIME-SCALE` and `TIMER-QUEUE-PAUSED-P` are setf-able. Repeating timers use bounded catch-up so a large frame delta cannot trigger an unbounded callback burst.

## Quaternions, inversion and geometry

```lisp
(let* ((q (lwlgl.math:quat-from-axis-angle
           (lwlgl.math:vec3 0 1 0)
           (lwlgl.math:degrees->radians 90)))
       (model (lwlgl.math:trs-mat4
               (lwlgl.math:vec3 0 0 -4) q
               (lwlgl.math:vec3 1 1 1))))
  (lwlgl.math:mat4-inverse model))
```

`AABB`, `RAY`, `RAY-AABB-INTERSECTION`, `PROJECT-POINT`, and `UNPROJECT-POINT` cover common picking and bounds workflows without introducing a physics engine.

LWLGL 0.4 adds planes, bounding spheres, ray/sphere queries and frustum culling:

```lisp
(let* ((projection (lwlgl.math:perspective-mat4
                    (lwlgl.math:degrees->radians 60)
                    (/ 16.0 9.0) 0.1 100.0))
       (view (lwlgl.math:look-at-mat4
              (lwlgl.math:vec3 0 2 5)
              (lwlgl.math:vec3 0 0 0)
              (lwlgl.math:vec3 0 1 0)))
       (frustum (lwlgl.math:frustum-from-matrix
                 (lwlgl.math:mat4-mul projection view)))
       (bounds (lwlgl.math:sphere (lwlgl.math:vec3 0 0 0) 2.0)))
  (lwlgl.math:frustum-intersects-sphere-p frustum bounds))
```

`FRUSTUM-INTERSECTS-AABB-P`, `FRUSTUM-CONTAINS-POINT-P`, `SPHERE-INTERSECTS-AABB-P`, and `RAY-SPHERE-INTERSECTION` cover common broad-phase visibility and picking queries.

## Profiling

```lisp
(let ((profiler (lwlgl.util:make-profiler)))
  (lwlgl.util:with-profiled-section (profiler :update)
    (update-world))
  (lwlgl.util:profiler-report profiler))
```

Each profile stat records count, total, last, minimum, maximum, and average duration.

## GLFW

```lisp
(lwlgl.glfw:with-glfw ()
  (lwlgl.glfw:with-window (window 1280 720 "Demo")
    (lwlgl.glfw:make-context-current window)
    ...))
```

Composable callbacks:

```lisp
(lwlgl.glfw:add-key-handler
 window
 (lambda (window key scancode action mods)
   (declare (ignore scancode mods))
   (when (and (= key lwlgl.glfw:key-escape)
              (= action lwlgl.glfw:press))
     (lwlgl.glfw:set-window-should-close window t))))
```

Monitor/gamepad examples:

```lisp
(dolist (monitor (lwlgl.glfw:get-monitors))
  (format t "~A: ~S~%" (lwlgl.glfw:monitor-name monitor)
          (lwlgl.glfw:monitor-video-mode monitor)))

(when (lwlgl.glfw:joystick-is-gamepad-p lwlgl.glfw:joystick-1)
  (multiple-value-bind (buttons axes)
      (lwlgl.glfw:gamepad-state lwlgl.glfw:joystick-1)
    ...))
```

## Stateful input

```lisp
(let ((input (lwlgl.input:make-input-state window)))
  (unwind-protect
       (progn
         (lwlgl.input:begin-input-frame input)
         (lwlgl.glfw:poll-events)
         (when (lwlgl.input:key-pressed-p input lwlgl.glfw:key-space)
           (jump)))
    (lwlgl.input:detach-input-state input)))
```

Call `BEGIN-INPUT-FRAME` immediately before event polling when you want transient events to belong to the current frame.


## Input action maps

```lisp
(let ((actions (lwlgl.input:make-action-map)))
  (lwlgl.input:bind-action
   actions :jump (lwlgl.input:key-binding lwlgl.glfw:key-space))
  (lwlgl.input:bind-axis
   actions :horizontal
   (lwlgl.input:key-binding lwlgl.glfw:key-a)
   (lwlgl.input:key-binding lwlgl.glfw:key-d))
  (values (lwlgl.input:action-pressed-p actions input :jump)
          (lwlgl.input:axis-value actions input :horizontal)))
```

Actions may have multiple keyboard/mouse bindings. Digital axes combine negative and positive bindings into `-1`, `0`, or `1`.

Composite bindings and 2D axes are available in 0.4:

```lisp
(lwlgl.input:bind-action
 actions :save
 (lwlgl.input:chord-binding
  (lwlgl.input:key-binding lwlgl.glfw:key-left-control)
  (lwlgl.input:key-binding lwlgl.glfw:key-s)))

(lwlgl.input:bind-action
 actions :confirm
 (lwlgl.input:any-binding
  (lwlgl.input:key-binding lwlgl.glfw:key-enter)
  (lwlgl.input:key-binding lwlgl.glfw:key-space)))

(lwlgl.input:bind-axis2
 actions :move
 (lwlgl.input:key-binding lwlgl.glfw:key-a)
 (lwlgl.input:key-binding lwlgl.glfw:key-d)
 (lwlgl.input:key-binding lwlgl.glfw:key-s)
 (lwlgl.input:key-binding lwlgl.glfw:key-w)
 :normalize t)

(multiple-value-bind (x y)
    (lwlgl.input:axis2-value actions input :move)
  ...)
```

`CHORD-BINDING` requires every child binding to be active. `ANY-BINDING` accepts any child. `:NORMALIZE T` prevents diagonal 2D movement from becoming faster than cardinal movement.

## Assets

```lisp
(let ((assets (lwlgl.assets:make-asset-manager :roots (list #P"assets/"))))
  (lwlgl.assets:register-asset-loader assets "glsl" #'lwlgl.assets:load-text-file)
  (lwlgl.assets:load-asset assets "shaders/basic.glsl")
  (lwlgl.assets:reload-changed-assets assets))
```

The manager resolves search roots, caches by resolved path and loader, supports explicit invalidation, and detects changed modification times for development-time reload workflows.

```lisp
(lwlgl.assets:preload-assets assets
                            '("shaders/world.vert"
                              "shaders/world.frag"))

(lwlgl.assets:add-asset-reload-listener
 assets
 (lambda (manager path value)
   (declare (ignore manager value))
   (format t "Reloaded ~A~%" path)))

(lwlgl.assets:cached-assets assets)
```

`PRELOAD-ASSETS` loads requests in order. `CACHED-ASSETS` returns metadata plists containing `:PATH`, `:WRITE-DATE`, and `:LOADER`. Reload listeners run after `RELOAD-CHANGED-ASSETS` refreshes a cached entry.

## Wavefront OBJ

```lisp
(let ((mesh (lwlgl.obj:load-obj #P"models/ship.obj")))
  (values (lwlgl.obj:obj-mesh-vertex-count mesh)
          (lwlgl.obj:obj-mesh-triangle-count mesh)
          (lwlgl.obj:obj-mesh-bounds mesh)))
```

The parser supports positions, UVs, normals, negative indices, polygon fan triangulation, and deduplicated indexed vertices. The interleaved vertex layout is `position.xyz | normal.xyz | texcoord.uv`.

## OpenGL

Required order:

```lisp
(lwlgl.glfw:make-context-current window)
(lwlgl.opengl:load-opengl)
```

Context information:

```lisp
(lwlgl.opengl:gl-info :include-extensions nil)
```

Shader program and matrix upload:

```lisp
(let ((program (lwlgl.opengl:make-program vertex-source fragment-source)))
  (unwind-protect
       (lwlgl.opengl:with-program (program)
         (let ((location (lwlgl.opengl:gl-get-uniform-location program "uMVP")))
           (lwlgl.opengl:set-uniform-mat4 location mvp)))
    (lwlgl.opengl:gl-delete-program program)))
```

Framebuffer helper:

```lisp
(multiple-value-bind (fbo color-texture depth-stencil)
    (lwlgl.opengl:create-color-framebuffer 1280 720)
  ;; render using FBO
  ...)
```

Instanced drawing uses `GL-VERTEX-ATTRIB-DIVISOR` with `GL-DRAW-ARRAYS-INSTANCED` or `GL-DRAW-ELEMENTS-INSTANCED`. See `examples/instanced-triangles.lisp`.


### GPU queries and synchronization

When the active context exposes the optional entry points:

```lisp
(let ((query (lwlgl.opengl:make-query)))
  (unwind-protect
       (progn
         (lwlgl.opengl:with-query (query lwlgl.opengl:time-elapsed)
           (render-scene))
         (lwlgl.opengl:query-result-ui64 query))
    (lwlgl.opengl:delete-query query)))
```

`MAKE-FENCE`, `WAIT-FENCE`, `DELETE-FENCE`, and `WITH-FENCE` expose OpenGL sync objects with explicit ownership.

## Graphics integration helpers

`lwlgl/gfx` composes otherwise independent subsystems without becoming a renderer:

```lisp
(lwlgl.gfx:make-program-from-files
 #P"shaders/world.vert" #P"shaders/world.frag"
 :include-dirs (list #P"shaders/include/")
 :defines '(("MAX_LIGHTS" . 8) "USE_FOG"))

(lwlgl.gfx:load-texture-2d #P"textures/albedo.png"
                           :srgb t :generate-mipmaps t)

(let ((mesh (lwlgl.obj:load-obj #P"models/ship.obj")))
  (lwlgl.gfx:with-gpu-mesh (gpu mesh)
    (lwlgl.gfx:draw-gpu-mesh gpu)))
```

The shader preprocessor supports recursive quoted/angle-bracket `#include`, include search directories, cycle detection, and compile-time defines.

## OpenAL and WAV

```lisp
(lwlgl.openal:with-openal ()
  (multiple-value-bind (source buffer)
      (lwlgl.openal:play-wav #P"sound.wav")
    (unwind-protect
         (lwlgl.openal:wait-source source)
      (lwlgl.openal:delete-source source)
      (lwlgl.openal:delete-buffer buffer))))
```


Device discovery and capture:

```lisp
(lwlgl.openal:openal-devices)
(lwlgl.openal:default-openal-device)
(lwlgl.openal:capture-devices)

(lwlgl.openal:with-capture-device
    (device :sample-rate 44100
            :format lwlgl.openal:format-mono16
            :buffer-samples 8192)
  (lwlgl.openal:start-capture device)
  (let ((count (lwlgl.openal:available-capture-samples device)))
    (when (plusp count)
      (lwlgl.openal:capture-samples device count)))
  (lwlgl.openal:stop-capture device))
```

For streaming, queue chunks with `QUEUE-PCM16`, query/recycle processed buffers with `UNQUEUE-PROCESSED-BUFFERS`, refill them, and queue them again.


## GLFW/Vulkan bridge

```lisp
(when (lwlgl.glfw:vulkan-supported-p)
  (lwlgl.glfw:required-vulkan-instance-extensions))
```

After the application owns a Vulkan instance, `CREATE-WINDOW-SURFACE` creates the GLFW window surface while leaving instance/device/swapchain policy to the caller.

## Vulkan loader discovery

```lisp
(let ((info (lwlgl.vulkan:vulkan-loader-info)))
  (format t "Vulkan ~D.~D.~D; ~D extensions~%"
          (getf info :major) (getf info :minor) (getf info :patch)
          (length (getf info :extensions))))
```

This remains bootstrap/discovery coverage, not full generated Vulkan commands.

## OpenCL discovery

```lisp
(dolist (platform (lwlgl.opencl:opencl-report))
  (format t "~A~%" (getf platform :name))
  (dolist (device (getf platform :devices))
    (format t "  ~A — ~D compute units~%"
            (getf device :name)
            (getf device :compute-units))))
```

## stb_image

Build the optional shim first, register its directory, then:

```lisp
(lwlgl.core:add-native-search-path #P"./native/build/")

(multiple-value-bind (width height channels)
    (lwlgl.stb:image-info #P"texture.png")
  (format t "~Dx~D (~D channels)~%" width height channels))

(lwlgl.stb:with-image (image #P"texture.png" :channels 4)
  (use-native-pixels (lwlgl.stb:image-pixels image)))
```

`LOAD-IMAGE-FROM-MEMORY` decodes an octet vector and `LOAD-HDR-IMAGE` returns float components.
