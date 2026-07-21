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


## From LWLGL 0.2 to 0.3

0.3 is additive for normal 0.2 callers. New optional systems are `lwlgl/assets`, `lwlgl/obj`, and `lwlgl/gfx`; the umbrella `:lwlgl` loads them automatically. Existing package-qualified public names are retained.

The OpenGL loader now has more optional query/sync entry points. Applications should continue using capability checks when targeting older contexts. New math, action-map, asset, OBJ, capture, and GLFW/Vulkan helpers do not replace the lower-level APIs.
