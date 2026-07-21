# Changelog

## 0.4.0

- Added planes, bounding spheres, ray/sphere intersection, sphere/AABB tests, frustum extraction from OpenGL clip matrices, and point/sphere/AABB frustum culling helpers.
- Added deterministic delta-driven timer queues with one-shot and repeating timers, pause/resume, cancellation, queue time scaling, and bounded catch-up.
- Added composite input bindings with `CHORD-BINDING` and `ANY-BINDING`, plus normalized two-dimensional digital axes through `BIND-AXIS2` / `AXIS2-VALUE`.
- Expanded the asset manager with bulk preloading, cached-asset metadata inspection, and reload listeners for development-time hot-reload workflows.
- Expanded the device-free test suite for spatial queries, timers, composite bindings, and 2D axes.
- Updated the English and Brazilian Portuguese documentation for the new 0.4 APIs and migration path.

## 0.3.2

- Fixed a Linux Wayland crash path where GLFW could load libdecor's GTK decoration plugin inside SBCL and corrupt the process during window startup. LWLGL now disables libdecor by default on detected Wayland sessions when supported by the runtime GLFW version.
- Added GLFW runtime version queries, initialization hints, startup diagnostics, and last-error reporting.
- Added `LWLGL_GLFW_PLATFORM=x11|wayland|auto|null` runtime backend selection on GLFW 3.4+, plus `LWLGL_GLFW_LIBDECOR=prefer|disable`.
- Improved GLFW initialization and window-creation errors with native error codes/descriptions.
- Preserved the scoped SBCL floating-point trap protection introduced in 0.3.1.

## 0.3.1

- Fixed SBCL `FLOATING-POINT-INVALID-OPERATION` failures that could occur while entering GLFW/native graphics code by isolating native multimedia calls from SBCL's default floating-point traps inside `WITH-GLFW`.
- Added `LWLGL.CORE:WITH-NATIVE-FLOATING-POINT-ENVIRONMENT` for explicit native-driver integration scopes.
- Documented the SBCL/GLFW floating-point trap symptom and diagnostic workaround.

## 0.3.0

- Reworked the README into the bilingual, code-first structure used by the MLish Compiler Kit project: overview/version, highlights, installation, quick tour, suggested architecture, documentation, limitations, and license.
- Added quaternion math: normalization, inversion, multiplication, axis-angle/Euler construction, SLERP, vector rotation, matrix conversion, and TRS matrices.
- Added generic 4x4 determinant/inversion, project/unproject helpers, AABBs, transformed bounds, rays, and ray/AABB intersections.
- Added lightweight named profiling statistics and `WITH-PROFILED-SECTION`.
- Added input action maps, multiple bindings per action, and digital axes.
- Added `lwlgl/assets` with asset search roots, extension-based loaders, caching, invalidation, and file-change reload detection.
- Added `lwlgl/obj`, a dependency-free Wavefront OBJ parser with negative indices, polygon fan triangulation, deduplicated indexed vertices, UVs/normals, and bounds.
- Added `lwlgl/gfx` with recursive GLSL include preprocessing, file-based shader programs, stb-backed OpenGL texture upload, and OBJ GPU mesh upload/drawing helpers.
- Added GLFW window content scale, opacity, attention requests, Vulkan availability, required-instance-extension discovery, and window-surface creation.
- Added optional OpenGL query-object and sync-fence APIs plus convenience helpers for GPU timing and synchronization.
- Added OpenAL playback/capture device discovery and low-level capture helpers.
- Added a device-free toolbox example and expanded the no-device tests.
- Added `run-tests.lisp` for a simple SBCL/ASDF test entry point.

## 0.2.0

- Renamed the project from CLWJGL to LWLGL (Lightweight Lisp Game Library).
- Added vector/matrix math, timing/fixed-step utilities, stateful input, broader GLFW/OpenGL/OpenAL coverage, WAV loading/streaming, enhanced stb_image, Vulkan discovery, OpenCL reports, and additional examples.

## 0.1.0

- Initial CLWJGL scaffold with modular Common Lisp/CFFI bindings for GLFW, OpenGL, OpenAL, Vulkan/OpenCL bootstrap, stb_image integration, examples, and bilingual documentation.
