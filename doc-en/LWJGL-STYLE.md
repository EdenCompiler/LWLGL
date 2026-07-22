# LWJGL-style API conventions

LWLGL 1.0 follows LWJGL's low-level organization while keeping Common Lisp naming and ownership explicit. This guide explains which package and function form to choose.

## Version packages

Use the package matching the native API level your application targets:

| API | Example package |
| --- | --- |
| OpenGL | `lwlgl.opengl.gl33`, `lwlgl.opengl.gl46` |
| OpenGL core profile | `lwlgl.opengl.gl33c`, `lwlgl.opengl.gl46c` |
| OpenGL ES | `lwlgl.opengles.gles20`, `lwlgl.opengles.gles32` |
| GLFW | `lwlgl.glfw.glfw34` |
| OpenAL / ALC | `lwlgl.openal.al11`, `lwlgl.openal.alc11` |
| OpenCL | `lwlgl.opencl.cl30` |
| Vulkan | `lwlgl.vulkan.vk14` |
| EGL | `lwlgl.egl.egl15` |

Later version packages re-export commands introduced by earlier versions. Choosing `GL33` therefore exposes the supported OpenGL commands through 3.3 without implying that a runtime context actually supports them; capabilities remain the runtime authority.

## Checked and raw calls

Checked entry points retain the native API prefix. Raw pointer-oriented entry points add `N`:

```lisp
(lwlgl.opengl.gl33:gl-clear
 lwlgl.opengl.gl33:+gl-color-buffer-bit+)

(lwlgl.opengl.gl33:ngl-clear
 lwlgl.opengl.gl33:+gl-color-buffer-bit+)
```

Prefer checked calls in application code. Use raw calls when implementing higher-level overloads, passing prevalidated native pointers, or matching a C ABI exactly.

GLFW follows the same convention:

```lisp
(lwlgl.glfw.glfw34:glfw-poll-events)
(lwlgl.glfw.glfw34:nglfw-poll-events)
```

Constants are surrounded by `+` and include the API prefix, for example `+GL-DEPTH-TEST+` and `+GLFW-KEY-ESCAPE+`.

## Binding calls versus helpers

Version packages are the canonical home for native calls and constants. Convenience functions stay in their subsystem package:

```lisp
;; Native binding calls.
(lwlgl.opengl.gl33:gl-bind-buffer
 lwlgl.opengl.gl33:+gl-array-buffer+ buffer)

;; Small Lisp helper implemented over those calls.
(lwlgl.opengl:upload-floats
 lwlgl.opengl.gl33:+gl-array-buffer+ vertices
 lwlgl.opengl.gl33:+gl-static-draw+)
```

This boundary makes it clear which code mirrors the native API and which code provides allocation, error handling, or resource-lifetime convenience.

## Context and device dispatch

OpenGL and OpenGL ES function pointers depend on an active context. Create capabilities after making the intended context current:

```lisp
(lwlgl.glfw.glfw34:glfw-make-context-current window)
(multiple-value-bind (complete missing capabilities)
    (lwlgl.opengl:load-opengl :error-on-missing nil)
  (declare (ignore complete missing))
  (lwlgl.opengl:with-capabilities (capabilities)
    ...))
```

Vulkan capabilities are associated with instances or devices. OpenAL and OpenCL expose providers and capability tables for the commands LWLGL currently wraps. Never copy a capability object from one unrelated context or device and assume its pointers remain valid.

## Compatibility names

The original friendly subsystem names remain available so older applications can migrate incrementally. New low-level code should prefer the version packages, as demonstrated by the files under `examples/`.
