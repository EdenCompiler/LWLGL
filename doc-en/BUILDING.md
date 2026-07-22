# Building and Native Dependencies

## Lisp dependencies

LWLGL currently needs:

- ASDF/UIOP
- CFFI

With Quicklisp:

```lisp
(ql:quickload :cffi)
(asdf:load-asd #P"/path/to/lwlgl/lwlgl.asd")
(asdf:load-system :lwlgl)
```

Examples live in the separate `lwlgl/examples` ASDF system:

```lisp
(asdf:load-system :lwlgl/examples)
(lwlgl.examples:toolbox-demo)
```

Alternatively, `(load #P"quickstart.lisp")` loads both the main library and the examples system.

## Linux

Install the native libraries you plan to use with your distribution package manager. Typical development/runtime packages provide:

- GLFW 3
- OpenAL Soft
- Vulkan loader
- OpenCL ICD loader
- a working OpenGL driver

Then verify:

```lisp
(lwlgl.core:print-runtime-report)
```

## Windows

Put required DLLs somewhere Windows can resolve them, or register a directory explicitly:

```lisp
(lwlgl.core:add-native-search-path #P"C:/my-game/native/")
```

Applications may also register a native bundle root. LWLGL first checks a platform directory such as `linux-x86-64/`, then the root itself, before falling back to system library names:

```lisp
(lwlgl.core:add-native-bundle-root #P"./natives/")
```

Common candidates recognized by LWLGL include `glfw3.dll`, `OpenAL32.dll`, `vulkan-1.dll` and `OpenCL.dll`.

## macOS

Framework paths are used for system OpenAL/OpenCL where appropriate. GLFW and Vulkan/MoltenVK still need to be installed separately when used.

For OpenGL 3.2+ core contexts on macOS, request the forward-compatible flag before creating the window. The examples already do this.

## Building the stb_image shim

The repository contains `native/lwlgl_stb.c`. It expects the official `stb_image.h` at:

```text
native/vendor/stb_image.h
```

If your archive does not include that upstream header, run the fetch helper while online:

```bash
./scripts/fetch-stb.sh
```

Then build:

```bash
./scripts/build-stb.sh
```

On Windows PowerShell:

```powershell
./scripts/fetch-stb.ps1
./scripts/build-stb.ps1
```

Finally register the output directory:

```lisp
(lwlgl.core:add-native-search-path #P"./native/build/")
```

The STB module is optional. The rest of LWLGL does not depend on the shim.

## Tests

Core tests do not require a display/audio device:

```lisp
(asdf:test-system :lwlgl/tests)
```

Graphics/audio examples require the corresponding native libraries and hardware/driver support.

## Binding generation

Declarative binding manifests live under `bindings/`; deterministic output is committed under `generated/`. Regenerate or verify it with:

```bash
sbcl --script scripts/generate-bindings.lisp
sbcl --script scripts/generate-bindings.lisp --check
```

Each output records its pinned upstream/curated revision and content fingerprint. Generated files must not be edited manually.

## SBCL: `FLOATING-POINT-INVALID-OPERATION` in GLFW or graphics drivers

SBCL normally enables traps for floating-point invalid operations, overflow and division by zero. Some native window-system/OpenGL driver paths may execute floating-point instructions that set those hardware exception flags even though the native API call itself can continue normally. Since LWLGL 0.3.2, the library masks these traps for the dynamic extent of `LWLGL.GLFW:WITH-GLFW` and restores the caller's previous floating-point mode afterwards.

Applications that call native multimedia libraries outside `WITH-GLFW` can explicitly use:

```lisp
(lwlgl.core:with-native-floating-point-environment ()
  ;; native/driver calls
  ...)
```

For diagnosis on SBCL, inspect the current modes with:

```lisp
(sb-int:get-floating-point-modes)
```
