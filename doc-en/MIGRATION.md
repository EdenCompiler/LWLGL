# Migrating from CLWJGL 0.1 to LWLGL 0.2

The library was renamed to **LWLGL — Lightweight Lisp Game Library**.

## Mechanical renames

- `clwjgl.asd` → `lwlgl.asd`
- `:clwjgl` → `:lwlgl`
- `:clwjgl/core` → `:lwlgl/core` (same pattern for all systems)
- `clwjgl.core` → `lwlgl.core` (same pattern for all packages)
- `clwjgl_stb` → `lwlgl_stb`

Most source migrations can be handled by a case-preserving project-wide replacement of `clwjgl` with `lwlgl`.

## Behavioral note: GLFW callbacks

Callback setters still install one application callback logically, but internally callbacks are now represented as composable handler lists. New `ADD-*-HANDLER` / `REMOVE-*-HANDLER` functions let utility layers such as `lwlgl/input` coexist with application callbacks.

## New systems

- `lwlgl/math`
- `lwlgl/util`
- `lwlgl/input`

The umbrella `:lwlgl` system loads them automatically.


## From LWLGL 0.3 to 0.4

0.4 is additive for normal 0.3 callers. Existing public names and subsystem boundaries remain available.

New APIs:

- `lwlgl/math`: `PLANE`, `SPHERE`, ray/sphere intersection, sphere/AABB overlap, `FRUSTUM-FROM-MATRIX`, and frustum point/sphere/AABB queries.
- `lwlgl/util`: deterministic `TIMER-QUEUE` scheduling with one-shot/repeating timers, cancellation, pause/resume, time scaling, and bounded catch-up.
- `lwlgl/input`: `CHORD-BINDING`, `ANY-BINDING`, and two-dimensional digital axes with `BIND-AXIS2` / `AXIS2-VALUE`.
- `lwlgl/assets`: `PRELOAD-ASSETS`, `CACHED-ASSETS`, and add/remove reload listeners.

The umbrella `:lwlgl` system still loads all modules. `lwlgl/tests` now also depends on `lwlgl/input` so the device-free test suite can validate composite bindings without opening a window.

## From LWLGL 0.2 to 0.3

0.3 is additive for normal 0.2 callers. New optional systems are `lwlgl/assets`, `lwlgl/obj`, and `lwlgl/gfx`; the umbrella `:lwlgl` loads them automatically. Existing package-qualified public names are retained.

The OpenGL loader now has more optional query/sync entry points. Applications should continue using capability checks when targeting older contexts. New math, action-map, asset, OBJ, capture, and GLFW/Vulkan helpers do not replace the lower-level APIs.

## From LWLGL 0.5 to 1.0

1.0 makes the LWJGL-style names the canonical low-level API. Existing friendly helper names remain available, but new binding code should:

- import a version package such as `lwlgl.opengl.gl33`, `lwlgl.glfw.glfw34`, `lwlgl.openal.al11`, `lwlgl.opencl.cl30`, or `lwlgl.vulkan.vk14`;
- call checked entry points with the API prefix (`GL-*`, `GLFW-*`, `AL-*`, `CL-*`, `VK-*`, `EGL-*`);
- call pointer-oriented raw entry points with the leading `N` only where required;
- use constants named `+API-NAME+` from version packages;
- create and bind capability objects explicitly for context/device-dispatched APIs;
- use `WITH-MEMORY-STACK` for temporary arguments and `MEM-ALLOC`/`MEM-FREE` for retained native storage.

OpenGL ES and EGL are new independent systems, `lwlgl/opengles` and `lwlgl/egl`. Registry coverage remains curated in 1.0, so use the capability predicates before optional calls.
