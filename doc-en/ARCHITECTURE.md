# LWLGL Architecture

## Purpose

LWLGL is a binding-and-runtime library, not an engine. It makes native multimedia/compute APIs practical from Common Lisp while preserving low-level ownership and control.

The codebase is split into four conceptual layers:

1. **Core runtime** — platform detection, native module registry, CFFI memory and diagnostics.
2. **Raw bindings** — constants, structs and C ABI declarations.
3. **Capability loaders** — runtime symbol lookup where required (especially OpenGL/Vulkan).
4. **Thin Lisp utilities** — scoped lifetime macros, resource helpers, math, timing, profiling, input, assets and format parsing.
5. **Optional integration helpers** — `lwlgl/gfx` composes OpenGL, stb_image and OBJ without defining renderer policy.

## ASDF dependency shape

```text
lwlgl/core
├── lwlgl/util
├── lwlgl/glfw ──┬── lwlgl/input
│                └── lwlgl/opengl ─── lwlgl/math
├── lwlgl/openal
├── lwlgl/vulkan
├── lwlgl/opencl
└── lwlgl/stb ──────────────┐
                            ├── lwlgl/gfx
lwlgl/obj ─── lwlgl/math ───┘
lwlgl/assets      (portable file/cache layer)
lwlgl/math        (pure Lisp)
lwlgl             (umbrella system)
```

Applications may load only the systems they need. The umbrella `:lwlgl` system loads everything for convenience.

## Native module registry

`REGISTER-NATIVE-MODULE` stores platform-specific candidate library names. `ENSURE-NATIVE-MODULE` loads a module lazily and remembers the successful CFFI handle. Additional directories can be registered with `ADD-NATIVE-SEARCH-PATH`.

This keeps native dependencies local to the feature that uses them.

## OpenGL capability loading

OpenGL entry points are registered with `DEFINE-GL-FUNCTION` and resolved through `glfwGetProcAddress` after a context becomes current.

```lisp
(lwlgl.glfw:make-context-current window)
(lwlgl.opengl:load-opengl)
```

The loader tracks required and optional functions separately. Missing required functions can fail `LOAD-OPENGL`; optional functions simply remain unavailable and can be tested with `GL-FUNCTION-AVAILABLE-P`.

Because capabilities belong to a context/driver combination, call `RELOAD-OPENGL` when switching to a materially different context.

## Callback routing

GLFW accepts one C callback pointer per event type, but Lisp applications often need multiple consumers. LWLGL installs static CFFI callbacks and routes them through handler lists keyed by native window address.

- `SET-*-HANDLER` replaces application handlers for that event.
- `ADD-*-HANDLER` composes another listener.
- `REMOVE-*-HANDLER` removes one listener.

This is what lets `lwlgl/input` track state without preventing game/application callbacks.

## Resource ownership

Native handles stay visible. Helpers reduce boilerplate without hiding ownership:

- `WITH-GLFW`, `WITH-WINDOW`, `WITH-OPENAL`, `WITH-IMAGE`
- `WITH-NATIVE-BUFFER`, `WITH-FOREIGN-ARRAY`
- OpenGL `WITH-BOUND-*` macros and explicit `MAKE-*` / `DELETE-*` pairs

Scoped helpers use `UNWIND-PROTECT` so cleanup also happens during non-local exits.

## Math representation

`lwlgl/math` is pure Lisp and does not depend on a native math library. `MAT4` values are 16-element single-float arrays in column-major order, so they can be uploaded directly with `SET-UNIFORM-MAT4`.

The math layer provides runtime fundamentals rather than a physics engine: vectors, matrices, quaternions, transform/projection helpers, AABBs, rays, planes, spheres, and frustums. Frustums are extracted from OpenGL-style clip matrices and expose point/sphere/AABB visibility tests suitable for renderer-side culling without imposing scene ownership.

## Timing model

`lwlgl/util` uses Common Lisp internal real time for a monotonic process-relative clock. `FRAME-CLOCK` tracks frame delta, elapsed time, frame count and an FPS estimate. `FIXED-STEP` separates simulation ticks from rendering and caps catch-up iterations to avoid an unbounded spiral of death.

`TIMER-QUEUE` is deliberately delta-driven instead of owning a thread or sleeping. Applications advance it from their existing frame/simulation clock. One-shot and repeating timers support cancellation, per-timer pause/resume, queue-wide pause/time scaling, and bounded catch-up. This preserves deterministic testability and leaves threading policy to the application.

## Input composition

`lwlgl/input` keeps device state separate from action interpretation. `KEY-BINDING` and `MOUSE-BINDING` are leaf descriptors; `CHORD-BINDING` and `ANY-BINDING` compose them recursively without installing additional native callbacks. `BIND-AXIS2` stores four directional binding sets and returns X/Y as multiple values, avoiding a dependency from the input system back into `lwlgl/math`.

## Expansion strategy

The handwritten API is organized so large generated bindings can be added later without changing the public architecture. Full Khronos coverage should be generated from official registries where possible, while curated wrappers remain small and optional.


## Assets, formats and integration

`lwlgl/assets` is intentionally independent of rendering. It resolves logical asset names against search roots, dispatches extension-based loaders, caches results, supports ordered bulk preloading and cache metadata inspection, and can detect modification-time changes for development workflows. Reload listeners provide a small notification hook after polling-based refreshes without turning the module into an OS file-watcher abstraction.

`lwlgl/obj` parses a focused Wavefront geometry subset into an indexed interleaved representation. `lwlgl/gfx` is the optional bridge that uploads that representation, expands GLSL includes, creates file-backed shader programs, and uploads stb-decoded images. Keeping this bridge separate prevents the core bindings from turning into a renderer.

## Native API growth

GLFW now exposes a small Vulkan bridge (`VULKAN-SUPPORTED-P`, required instance extensions, and window-surface creation). OpenGL query/sync entry points are optional capabilities. OpenAL device enumeration and capture remain explicit low-level ALC operations. These features preserve the same ownership-first model as the original binding layer.
