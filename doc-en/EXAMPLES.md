# Example guide

The examples are executable documentation for LWLGL 1.0. Load them with `lwlgl/examples` or use the command-line runner.

```bash
sbcl --script scripts/run-examples.lisp
sbcl --script scripts/run-examples.lisp toolbox native-memory capabilities
```

Pass `--smoke` to limit interactive window and audio examples for unattended validation:

```bash
sbcl --script scripts/run-examples.lisp --smoke spinning-cube triangle audio
```

## Available examples

| Runner name | Lisp function | Requirements | Demonstrates |
| --- | --- | --- | --- |
| `toolbox` | `toolbox-demo` | none | math, timers, profiling, OBJ |
| `native-memory` | `native-memory-demo` | none | cursor buffers, stack allocation, UTF-8 |
| `capabilities` | `capabilities-demo` | none | providers, capability tables, version packages |
| `system-info` | `system-info` | optional native loaders | monitors, Vulkan, OpenCL |
| `opengl-info` | `opengl-info` | GLFW and OpenGL | hidden context and resolved commands |
| `egl-info` | `egl-info` | EGL and a display backend | default display initialization |
| `hello-window` | `hello-window` | GLFW and OpenGL | minimal context and clear loop |
| `triangle` | `triangle` | OpenGL 3.3 | shaders, VAO, VBO, attributes |
| `spinning-cube` | `spinning-cube` | OpenGL 3.3 | indexed 3D rendering and MVP matrices |
| `textured-quad` | `textured-quad` | OpenGL 3.3 | procedural textures and UVs |
| `offscreen-framebuffer` | `offscreen-framebuffer` | OpenGL 3.3 | framebuffer rendering and pixel readback |
| `instanced-triangles` | `instanced-triangles` | OpenGL 3.3 | per-instance attributes |
| `input` | `input-demo` | GLFW and OpenGL | frame input and timing |
| `audio` | `audio-tone` | OpenAL | generated PCM playback |
| `positional-audio` | `positional-audio` | OpenAL | moving spatial source and listener |
| `vulkan-readiness` | `vulkan-readiness` | GLFW and Vulkan | no-API window and instance requirements |

## Spinning cube walkthrough

`examples/spinning-cube.lisp` deliberately uses both layers of the 1.0 API:

1. `GLFW34` creates a 3.3 core context.
2. `lwlgl.opengl:load-opengl` resolves context-specific pointers.
3. A VAO owns vertex-format and element-buffer state.
4. A VBO contains interleaved positions and colors; an EBO contains 36 indices.
5. Depth testing makes the nearest cube surfaces win.
6. Each frame combines X/Y model rotations, a translated view, and a resize-aware perspective projection.
7. `SET-UNIFORM-MAT4` uploads the resulting column-major MVP matrix.
8. `GL-DRAW-ELEMENTS` renders the indexed cube.

The example accepts `:MAX-FRAMES`, which is useful for tests:

```lisp
(lwlgl.examples:spinning-cube :max-frames 2)
```

Without that argument it runs until Escape or the window close button.

## Display selection on Linux

If GLFW selects an unavailable Wayland endpoint, request X11 before starting Lisp:

```bash
LWLGL_GLFW_PLATFORM=x11 sbcl --script scripts/run-examples.lisp spinning-cube
```

Use `system-info` and `opengl-info` first when diagnosing loader, display, or driver issues.
