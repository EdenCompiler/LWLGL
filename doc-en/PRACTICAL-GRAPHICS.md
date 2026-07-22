# Practical graphics workflows

This guide connects the small LWLGL examples to common application tasks. All commands remain part of LWLGL 1.0.0.

## Procedural textures

`examples/textured-quad.lisp` creates a checkerboard in a Lisp `(UNSIGNED-BYTE 8)` array, temporarily exposes it as native memory, and uploads it with `CREATE-TEXTURE-2D`.

The important lifetime rule is that OpenGL copies the pixels during `GL-TEX-IMAGE-2D`; the temporary CFFI array can be released immediately after that call. The resulting texture handle remains application-owned and is deleted explicitly.

```bash
sbcl --script scripts/run-examples.lisp textured-quad
```

The example also shows an interleaved position/UV VBO, an EBO, nearest-neighbor filtering, texture-unit selection, a sampler uniform, and indexed drawing.

## Offscreen rendering and readback

`examples/offscreen-framebuffer.lisp` creates a hidden OpenGL context and an RGBA framebuffer, clears it, waits for completion, and copies the center pixel into a Lisp byte vector.

```bash
sbcl --script scripts/run-examples.lisp offscreen-framebuffer
```

This is the basic shape used for screenshots, selection buffers, generated thumbnails, GPU tests, and render-to-texture pipelines:

```text
create color texture + framebuffer
             ↓
bind framebuffer → render → synchronize
             ↓
read pixels or sample the color texture later
             ↓
unbind and delete framebuffer-owned resources
```

Real-time applications should avoid synchronous readback every frame because it can stall the graphics pipeline. Prefer asynchronous staging/PBO strategies once those commands are present in the binding surface.

## Indexed 3D rendering

`examples/spinning-cube.lisp` is the compact 3D baseline: VBO, EBO, VAO, depth testing, resize-aware projection, model/view/projection composition, uniform upload, and indexed drawing.

The math package stores matrices in OpenGL-friendly column-major order. Build the transform in application order and upload it without transposition:

```lisp
(let ((mvp (lwlgl.math:mat4-mul
            projection (lwlgl.math:mat4-mul view model))))
  (lwlgl.opengl:set-uniform-mat4 location mvp))
```

## Vulkan window readiness

`examples/vulkan-readiness.lisp` performs the practical work LWLGL's current Vulkan bootstrap layer supports:

- verifies that GLFW sees a Vulkan loader and ICD;
- creates a window with `GLFW_NO_API`;
- reads the loader API version, extensions, and layers;
- compares GLFW-required surface extensions with loader extensions;
- reports whether the Khronos validation layer is installed.

```bash
sbcl --script scripts/run-examples.lisp vulkan-readiness
```

The example deliberately stops before instance creation. LWLGL 1.0 currently exposes Vulkan loader/bootstrap introspection, not the full generated instance/device/swapchain/render-command surface. A complete Vulkan renderer will build on the exact extension list this example produces when that coverage is added.

## Graphics-adjacent native systems

`opengl-info` validates context command resolution, `egl-info` validates the default EGL display, and `system-info` combines monitor, Vulkan, and OpenCL reporting. `positional-audio` demonstrates the same explicit native-resource pattern with OpenAL by moving a mono source relative to the listener.

For unattended local verification:

```bash
sbcl --script scripts/run-examples.lisp --smoke textured-quad spinning-cube positional-audio
sbcl --script scripts/run-examples.lisp offscreen-framebuffer vulkan-readiness
```
