# LWLGL — Lightweight Lisp Game Library

> **Languages / Idiomas:** [English](#english) · [Português do Brasil](#português-do-brasil)

---

# English

LWLGL is a modular Common Lisp library for low-level game, graphics, audio, compute, and native-platform programming in the spirit of LWJGL. It does not try to be a game engine; instead, it provides composable bindings and thin utilities around GLFW, OpenGL, OpenAL, Vulkan loader discovery, OpenCL discovery, and stb_image, plus Lisp-native math, input, assets, profiling, OBJ loading, and graphics integration helpers.

Current version: 0.4.1.

## Highlights

- modular ASDF systems: load only the subsystems an application needs;
- cross-platform native-library discovery for Windows, Linux, and macOS;
- CFFI-based native memory buffers, temporary foreign arrays, symbol resolution, and runtime diagnostics;
- GLFW window/context lifecycle, monitors, video modes, callbacks, clipboard, joysticks, gamepads, content scale, opacity, attention requests, and Vulkan interop;
- composable GLFW callback handlers, allowing library-level input tracking and application callbacks to coexist;
- stateful keyboard/mouse input with pressed/down/released transitions, text input, deltas, scrolling, and focus state;
- named input action maps, composite chords/alternatives, one-dimensional axes, and normalized two-dimensional digital axes;
- runtime-loaded OpenGL entry points with required/optional capability tracking;
- OpenGL buffers, VAOs, shaders, programs, textures, framebuffers, renderbuffers, UBOs, instancing, state control, pixel readback, GPU queries, and sync fences;
- OpenGL shader compilation/link conditions carrying native info logs;
- vector, matrix, quaternion, transform, projection, ray, AABB, sphere, plane, and frustum-culling math in OpenGL-friendly column-major form;
- frame clocks, fixed-timestep simulation, interpolation helpers, deterministic timer queues, and lightweight named profiling statistics;
- OpenAL playback, spatial source/listener controls, queued streaming buffers, PCM WAV loading, device enumeration, and capture-device helpers;
- stb_image file/memory loading, image metadata, HDR detection/loading, and vertical-flip control;
- Vulkan loader version, instance extension/layer discovery, plus GLFW-required extensions and window-surface creation helpers;
- OpenCL platform/device discovery with compute units, clock, work-group limits, memory, driver, version, profile, availability, and extensions;
- asset search roots, extension-based loaders, bulk preloading, cache inspection/invalidation, changed-file reload detection, and reload listeners;
- dependency-free Wavefront OBJ parsing with fan triangulation, negative indices, deduplicated indexed vertices, bounds, normals, and UVs;
- graphics integration helpers for recursive GLSL `#include`, program creation from files, stb-backed texture upload, and OBJ-to-VAO/VBO/EBO upload;
- runnable examples for windows, triangles, instancing, input/timing, audio, native-system discovery, and the device-free utility toolbox;
- English and Brazilian Portuguese documentation.

## Installation

LWLGL requires a Common Lisp implementation supported by CFFI and an ASDF-visible installation of `cffi`. Native subsystems also require the corresponding platform libraries, such as GLFW, OpenAL, OpenGL, Vulkan, or OpenCL, when those systems are used.

Place the repository somewhere ASDF can find it, then load the complete system:

    (asdf:load-system :lwlgl)

Or load only selected subsystems:

    (asdf:load-system :lwlgl/math)
    (asdf:load-system :lwlgl/glfw)
    (asdf:load-system :lwlgl/opengl)
    (asdf:load-system :lwlgl/openal)
    (asdf:load-system :lwlgl/assets)
    (asdf:load-system :lwlgl/obj)
    (asdf:load-system :lwlgl/gfx)

The included convenience loader also works when invoked from the project directory:

    (load #P"quickstart.lisp")

Load the examples:

    (asdf:load-system :lwlgl/examples)

    (lwlgl.examples:hello-window)
    (lwlgl.examples:triangle)
    (lwlgl.examples:instanced-triangles)
    (lwlgl.examples:input-demo)
    (lwlgl.examples:audio-tone)
    (lwlgl.examples:system-info)
    (lwlgl.examples:toolbox-demo)

Run the device-free test suite with SBCL:

    sbcl --script run-tests.lisp

The tests cover native-memory helpers, module registration, platform/version reporting, vectors, matrices and inversion, quaternions, rays/AABBs/spheres/frustums, deterministic timers, composite input bindings and 2D axes, fixed timesteps, profiling, OBJ parsing, and asset-loader registration without requiring a window, GPU, or audio device.

### stb_image shim

The `lwlgl/stb` subsystem uses a tiny C shim around the single-header `stb_image` library. Fetch the upstream header and build the shim with the provided scripts:

    ./scripts/fetch-stb.sh
    ./scripts/build-stb.sh

PowerShell equivalents are available under `scripts/` for Windows.

## Quick tour

### Window and OpenGL context

    (lwlgl.glfw:with-glfw ()
      (lwlgl.glfw:default-window-hints)
      (lwlgl.glfw:window-hint lwlgl.glfw:context-version-major 3)
      (lwlgl.glfw:window-hint lwlgl.glfw:context-version-minor 3)
      (lwlgl.glfw:window-hint lwlgl.glfw:opengl-profile
                               lwlgl.glfw:opengl-core-profile)

      (lwlgl.glfw:with-window (window 1280 720 "LWLGL")
        (lwlgl.glfw:make-context-current window)
        (lwlgl.glfw:swap-interval 1)
        (lwlgl.opengl:load-opengl)

        (loop until (lwlgl.glfw:window-should-close-p window) do
          (lwlgl.opengl:gl-clear-color 0.08 0.09 0.12 1.0)
          (lwlgl.opengl:gl-clear lwlgl.opengl:color-buffer-bit)
          (lwlgl.glfw:swap-buffers window)
          (lwlgl.glfw:poll-events))))

OpenGL functions are resolved from the current context through GLFW. `load-opengl` tracks required and optional functions, while `gl-capabilities` and `gl-function-available-p` allow capability-driven code paths.

### Math, quaternions, and collision primitives

    (let* ((rotation
             (lwlgl.math:quat-from-axis-angle
               (lwlgl.math:vec3 0 1 0)
               (lwlgl.math:degrees->radians 90)))
           (model
             (lwlgl.math:trs-mat4
               (lwlgl.math:vec3 3 0 -5)
               rotation
               (lwlgl.math:vec3 1 1 1)))
           (inverse (lwlgl.math:mat4-inverse model)))
      (values model inverse))

Geometry helpers include AABBs and rays:

    (let ((box (lwlgl.math:aabb
                 (lwlgl.math:vec3 -1 -1 -1)
                 (lwlgl.math:vec3  1  1  1)))
          (ray (lwlgl.math:ray
                 (lwlgl.math:vec3 -5 0 0)
                 (lwlgl.math:vec3  1 0 0))))
      (lwlgl.math:ray-aabb-intersection ray box))
    ;; => 4.0, 6.0 as entry/exit distances

Spatial queries also include spheres, planes, ray/sphere tests, and view-frustum culling:

    (let* ((projection (lwlgl.math:perspective-mat4
                         (lwlgl.math:degrees->radians 60)
                         (/ 16.0 9.0) 0.1 100.0))
           (view (lwlgl.math:look-at-mat4
                  (lwlgl.math:vec3 0 2 5)
                  (lwlgl.math:vec3 0 0 0)
                  (lwlgl.math:vec3 0 1 0)))
           (frustum (lwlgl.math:frustum-from-matrix
                     (lwlgl.math:mat4-mul projection view)))
           (bounds (lwlgl.math:sphere (lwlgl.math:vec3 0 0 0) 1.5)))
      (lwlgl.math:frustum-intersects-sphere-p frustum bounds))

### Stateful input and action maps

Attach one input state to a window and clear one-frame transitions before polling events:

    (let* ((input (lwlgl.input:make-input-state window))
           (actions (lwlgl.input:make-action-map)))
      (lwlgl.input:bind-action
        actions :jump
        (lwlgl.input:key-binding lwlgl.glfw:key-space))

      (lwlgl.input:bind-axis
        actions :horizontal
        (lwlgl.input:key-binding lwlgl.glfw:key-a)
        (lwlgl.input:key-binding lwlgl.glfw:key-d))

      (lwlgl.input:begin-input-frame input)
      (lwlgl.glfw:poll-events)

      (when (lwlgl.input:action-pressed-p actions input :jump)
        (format t "Jump!~%"))

      (format t "Horizontal axis: ~A~%"
              (lwlgl.input:axis-value actions input :horizontal)))

Action bindings sit above the raw GLFW key/mouse APIs without replacing them. Composite bindings support shortcuts and alternatives, while `BIND-AXIS2` builds WASD/D-pad style movement without adding a math dependency:

    (lwlgl.input:bind-action
      actions :save
      (lwlgl.input:chord-binding
        (lwlgl.input:key-binding lwlgl.glfw:key-left-control)
        (lwlgl.input:key-binding lwlgl.glfw:key-s)))

    (lwlgl.input:bind-axis2
      actions :move
      (lwlgl.input:key-binding lwlgl.glfw:key-a)
      (lwlgl.input:key-binding lwlgl.glfw:key-d)
      (lwlgl.input:key-binding lwlgl.glfw:key-s)
      (lwlgl.input:key-binding lwlgl.glfw:key-w)
      :normalize t)

    (multiple-value-bind (x y)
        (lwlgl.input:axis2-value actions input :move)
      (move-player x y))

### Asset roots and reload detection

    (defparameter *assets*
      (lwlgl.assets:make-asset-manager
        :roots (list #P"assets/" #P"shared-assets/")))

    (lwlgl.assets:register-asset-loader
      *assets* "glsl" #'lwlgl.assets:load-text-file)

    (defparameter *shader-source*
      (lwlgl.assets:load-asset *assets* "shaders/basic.glsl"))

    ;; Later, for editor/development workflows:
    (lwlgl.assets:reload-changed-assets *assets*)

A cache entry is keyed by resolved file and loader. `load-asset` can automatically refresh an entry when the file modification time changes, while explicit invalidation and full-cache clearing are also available. `PRELOAD-ASSETS` performs ordered bulk loads, `CACHED-ASSETS` exposes cache metadata, and reload listeners receive `(manager path value)` after `RELOAD-CHANGED-ASSETS` refreshes a cached file.

### OBJ loading and GPU upload

    (let ((mesh (lwlgl.obj:load-obj #P"models/ship.obj")))
      (format t "~D vertices, ~D triangles~%"
              (lwlgl.obj:obj-mesh-vertex-count mesh)
              (lwlgl.obj:obj-mesh-triangle-count mesh))

      (lwlgl.gfx:with-gpu-mesh (gpu mesh)
        (lwlgl.gfx:draw-gpu-mesh gpu)))

The OBJ parser emits an indexed interleaved stream with this layout:

    position.xyz | normal.xyz | texcoord.uv

`lwlgl/gfx` configures those fields at OpenGL attribute locations 0, 1, and 2 respectively.

### Shader includes and file-based programs

    (defparameter *program*
      (lwlgl.gfx:make-program-from-files
        #P"shaders/world.vert"
        #P"shaders/world.frag"
        :include-dirs (list #P"shaders/include/")
        :defines '(("MAX_LIGHTS" . 8) "USE_FOG")))

The preprocessor recursively expands `#include "file"` and `#include <file>`, searches the including file's directory before additional include directories, and reports include cycles/missing files with an include stack.

### Image-to-texture loading

    (multiple-value-bind (texture width height channels)
        (lwlgl.gfx:load-texture-2d
          #P"textures/albedo.png"
          :srgb t
          :generate-mipmaps t)
      (format t "Texture ~D: ~Dx~D, ~D channels~%"
              texture width height channels))

Decoded stb_image memory is released after the pixels are uploaded to OpenGL.

### GPU timing queries and fences

When supported by the active OpenGL context:

    (let ((query (lwlgl.opengl:make-query)))
      (unwind-protect
           (progn
             (lwlgl.opengl:with-query (query lwlgl.opengl:time-elapsed)
               (render-scene))
             ;; Result is nanoseconds for GL_TIME_ELAPSED.
             (lwlgl.opengl:query-result-ui64 query))
        (lwlgl.opengl:delete-query query)))

Sync helpers expose fence creation, client waits, and deterministic cleanup through `with-fence`.

### OpenAL devices and audio capture

    (lwlgl.openal:openal-devices)
    (lwlgl.openal:default-openal-device)
    (lwlgl.openal:capture-devices)

Capture helpers expose the ALC capture API without imposing a recording framework:

    (lwlgl.openal:with-capture-device
        (device :sample-rate 44100
                :format lwlgl.openal:format-mono16
                :buffer-samples 8192)
      (lwlgl.openal:start-capture device)
      ;; ... wait/poll in the application ...
      (let ((available (lwlgl.openal:available-capture-samples device)))
        (when (plusp available)
          (lwlgl.openal:capture-samples device available)))
      (lwlgl.openal:stop-capture device))

### Vulkan window bootstrap through GLFW

    (when (lwlgl.glfw:vulkan-supported-p)
      (format t "Required instance extensions: ~S~%"
              (lwlgl.glfw:required-vulkan-instance-extensions)))

After an application creates a Vulkan instance, `create-window-surface` bridges a no-API GLFW window to a `VkSurfaceKHR`. LWLGL deliberately leaves instance/device/swapchain policy to the application.

### Timing and profiling

    (let ((clock (lwlgl.util:make-frame-clock))
          (profiler (lwlgl.util:make-profiler)))
      (lwlgl.util:with-profiled-section (profiler :update)
        (update-world))

      (multiple-value-bind (dt elapsed fps)
          (lwlgl.util:tick-frame-clock clock)
        (declare (ignore elapsed))
        (format t "dt=~A fps=~A~%" dt fps))

      (dolist (stat (lwlgl.util:profiler-report profiler))
        (format t "~A total=~A average=~A~%"
                (lwlgl.util:profile-stat-name stat)
                (lwlgl.util:profile-stat-total stat)
                (lwlgl.util:profile-stat-average stat))))

The profiler is intentionally simple: it records named wall/process-time samples and aggregates count, total, last, minimum, maximum, and average. Delta-driven timer queues can use the same frame delta:

    (let ((timers (lwlgl.util:make-timer-queue)))
      (lwlgl.util:schedule-timer timers 2.0d0 #'open-door)
      (lwlgl.util:schedule-repeating-timer timers 0.5d0 #'spawn-particle)
      ;; once per frame:
      (lwlgl.util:advance-timers timers dt))

Timer queues support pause/resume, cancellation, queue-wide time scaling, and bounded catch-up for repeating timers.

## Suggested architecture

    application
      -> lwlgl/core
           -> native-module registry
           -> CFFI memory / symbol utilities
      -> platform + devices
           -> lwlgl/glfw
           -> lwlgl/input
           -> lwlgl/openal
      -> rendering
           -> lwlgl/opengl
           -> lwlgl/stb
           -> lwlgl/obj
           -> lwlgl/gfx integration helpers
      -> compute / explicit graphics bootstrap
           -> lwlgl/vulkan
           -> lwlgl/opencl
      -> portable support
           -> lwlgl/math
           -> lwlgl/util
           -> lwlgl/assets
      -> application-owned renderer / game architecture

The intended boundary is deliberate: LWLGL supplies low-level capabilities and small reusable utilities; the application remains responsible for scene architecture, ECS decisions, renderer policy, asset formats, threading, networking, physics, and gameplay systems.

## Systems

- `lwlgl/core` — platform detection, native modules, memory, symbol lookup, diagnostics;
- `lwlgl/math` — vectors, matrices, quaternions, transforms, projections, rays, AABBs, spheres, planes, and frustums;
- `lwlgl/util` — clocks, fixed timestep, interpolation, deterministic timers, and profiling;
- `lwlgl/glfw` — windows, contexts, monitors, input devices, callbacks, Vulkan bridge;
- `lwlgl/input` — frame-state input, composite action bindings, 1D axes, and 2D axes;
- `lwlgl/assets` — asset roots, loaders, preload, cache inspection, change detection, and reload listeners;
- `lwlgl/obj` — Wavefront OBJ loading;
- `lwlgl/opengl` — runtime-loaded OpenGL calls and helpers;
- `lwlgl/openal` — playback, WAV, streaming, discovery, capture;
- `lwlgl/vulkan` — loader/bootstrap introspection;
- `lwlgl/opencl` — compute-platform/device discovery;
- `lwlgl/stb` — stb_image integration;
- `lwlgl/gfx` — cross-module OpenGL integration helpers;
- `lwlgl/examples` — runnable examples;
- `lwlgl/tests` — device-free tests.

## Documentation

The English documentation is in `doc-en/`:

- `API.md` — compact subsystem/API reference;
- `ARCHITECTURE.md` — module boundaries and extension model;
- `BUILDING.md` — ASDF/native-library/stb build notes;
- `MIGRATION.md` — migration from the original CLWJGL naming and earlier LWLGL releases.

The Brazilian Portuguese documentation is in `doc-ptbr/`.

The examples under `examples/` are also intended as executable documentation.

## Linux / Wayland startup safety

LWLGL 0.3.2 disables GLFW's optional libdecor GTK plugin by default on detected Wayland sessions. This avoids a class of host-runtime crashes seen when GTK/libdecor is loaded inside SBCL. Override the backend before starting SBCL when needed:

```bash
LWLGL_GLFW_PLATFORM=x11 sbcl       # force X11/XWayland on GLFW 3.4+
LWLGL_GLFW_PLATFORM=wayland sbcl   # force native Wayland on GLFW 3.4+
LWLGL_GLFW_LIBDECOR=prefer sbcl    # opt back into libdecor
```

Inspect startup state from Lisp with `(lwlgl.glfw:glfw-diagnostics)`.

## Current limitations

### SBCL and native floating-point traps

LWLGL 0.3.2 protects `lwlgl.glfw:with-glfw` from SBCL floating-point traps that can be triggered inside native window-system or graphics-driver code. If you integrate another native multimedia API directly, wrap that native scope with `lwlgl.core:with-native-floating-point-environment`.

Version 0.4.1 is still an early low-level library. Vulkan is a loader/bootstrap layer rather than generated full Vulkan bindings; OpenCL focuses on discovery rather than complete compute-command coverage; the OBJ loader intentionally targets the common geometry subset and does not yet implement MTL/material parsing, smoothing-group-generated normals, or every vendor extension; `lwlgl/gfx` is a convenience integration layer rather than a renderer; stb_image requires the bundled shim to be built; and native APIs still depend on platform libraries supplied by the host system or application.

Important future directions include generated Vulkan/OpenGL/OpenAL/OpenCL bindings, richer OpenGL debug output and indirect/multi-draw APIs, cursor/image/window-icon helpers, audio streaming abstractions, MTL and glTF import paths, font/text bindings, controller mapping management, native packaging, CI across multiple Lisp implementations, and broader executable tests on real graphics/audio devices.

## License

MIT. See `LICENSE`.

---

# Português do Brasil

LWLGL é uma biblioteca modular em Common Lisp para programação de baixo nível voltada a jogos, gráficos, áudio, computação e integração nativa, no espírito do LWJGL. Ela não tenta ser um motor de jogos; em vez disso, oferece bindings componíveis e utilitários finos para GLFW, OpenGL, OpenAL, descoberta do carregador Vulkan, descoberta OpenCL e stb_image, além de matemática, input, assets, profiling, carregamento OBJ e integração gráfica escritos em Lisp.

Versão atual: 0.4.1.

## Destaques

- sistemas ASDF modulares: carregue apenas os subsistemas necessários;
- descoberta multiplataforma de bibliotecas nativas para Windows, Linux e macOS;
- buffers de memória nativa via CFFI, arrays estrangeiros temporários, resolução de símbolos e diagnóstico de runtime;
- GLFW para janelas/contextos, monitores, modos de vídeo, callbacks, clipboard, joysticks, gamepads, escala de conteúdo, opacidade, pedido de atenção e interoperabilidade Vulkan;
- handlers GLFW componíveis, permitindo que o rastreamento de input da biblioteca e callbacks da aplicação coexistam;
- input stateful de teclado/mouse com transições pressionado/segurado/solto, texto Unicode, deltas, scroll e foco;
- mapas de ações nomeadas, chords/alternativas compostas, eixos digitais 1D e eixos digitais 2D normalizados;
- funções OpenGL carregadas em runtime, com rastreamento de capacidades obrigatórias e opcionais;
- buffers, VAOs, shaders, programas, texturas, framebuffers, renderbuffers, UBOs, instancing, estado gráfico, leitura de pixels, queries de GPU e fences de sincronização;
- condições Lisp para erros de compilação/link de shaders contendo os logs nativos;
- vetores, matrizes, quaternions, transforms, projeções, rays, AABBs, esferas, planos e frustum culling em formato column-major amigável ao OpenGL;
- relógios de frame, simulação em timestep fixo, interpolação, filas determinísticas de timers e profiling leve por seções nomeadas;
- OpenAL com reprodução, áudio espacial, streaming por filas, WAV PCM, enumeração de dispositivos e captura de áudio;
- stb_image para arquivos/memória, metadados, HDR e flip vertical;
- versão/extensões/layers do carregador Vulkan, extensões exigidas pelo GLFW e criação de surface de janela;
- descoberta OpenCL com compute units, clock, work-group, memória, driver, versão, perfil, disponibilidade e extensões;
- raízes de assets, loaders por extensão, preload em lote, inspeção/invalidação de cache, detecção/reload de arquivos alterados e listeners de reload;
- parser Wavefront OBJ sem dependências extras, com triangulação em leque, índices negativos, vértices indexados deduplicados, bounds, normals e UVs;
- integração gráfica para `#include` GLSL recursivo, programas a partir de arquivos, upload de texturas via stb e upload OBJ para VAO/VBO/EBO;
- exemplos executáveis de janela, triângulos, instancing, input/timing, áudio, descoberta do sistema nativo e utilitários sem dispositivo;
- documentação em inglês e português do Brasil.

## Instalação

LWLGL requer uma implementação Common Lisp suportada pelo CFFI e uma instalação de `cffi` visível ao ASDF. Subsistemas nativos também exigem as bibliotecas correspondentes, como GLFW, OpenAL, OpenGL, Vulkan ou OpenCL, quando utilizados.

Coloque o repositório em um local visível ao ASDF e carregue o sistema completo:

    (asdf:load-system :lwlgl)

Ou carregue apenas subsistemas específicos:

    (asdf:load-system :lwlgl/math)
    (asdf:load-system :lwlgl/glfw)
    (asdf:load-system :lwlgl/opengl)
    (asdf:load-system :lwlgl/openal)
    (asdf:load-system :lwlgl/assets)
    (asdf:load-system :lwlgl/obj)
    (asdf:load-system :lwlgl/gfx)

O carregador auxiliar incluído também pode ser usado a partir do diretório do projeto:

    (load #P"quickstart.lisp")

Carregue os exemplos:

    (asdf:load-system :lwlgl/examples)

    (lwlgl.examples:hello-window)
    (lwlgl.examples:triangle)
    (lwlgl.examples:instanced-triangles)
    (lwlgl.examples:input-demo)
    (lwlgl.examples:audio-tone)
    (lwlgl.examples:system-info)
    (lwlgl.examples:toolbox-demo)

Execute a suíte de testes sem dispositivo com SBCL:

    sbcl --script run-tests.lisp

Os testes cobrem memória nativa, registro de módulos, plataforma/versão, vetores, matrizes e inversão, quaternions, interseção ray/AABB, timestep fixo, profiling, parser OBJ e registro de loaders de assets sem exigir janela, GPU ou dispositivo de áudio.

### Shim stb_image

O subsistema `lwlgl/stb` usa um pequeno shim C sobre a biblioteca single-header `stb_image`. Baixe o header upstream e compile o shim com os scripts incluídos:

    ./scripts/fetch-stb.sh
    ./scripts/build-stb.sh

Há equivalentes PowerShell em `scripts/` para Windows.

## Visão rápida

### Janela e contexto OpenGL

    (lwlgl.glfw:with-glfw ()
      (lwlgl.glfw:default-window-hints)
      (lwlgl.glfw:window-hint lwlgl.glfw:context-version-major 3)
      (lwlgl.glfw:window-hint lwlgl.glfw:context-version-minor 3)
      (lwlgl.glfw:window-hint lwlgl.glfw:opengl-profile
                               lwlgl.glfw:opengl-core-profile)

      (lwlgl.glfw:with-window (window 1280 720 "LWLGL")
        (lwlgl.glfw:make-context-current window)
        (lwlgl.glfw:swap-interval 1)
        (lwlgl.opengl:load-opengl)

        (loop until (lwlgl.glfw:window-should-close-p window) do
          (lwlgl.opengl:gl-clear-color 0.08 0.09 0.12 1.0)
          (lwlgl.opengl:gl-clear lwlgl.opengl:color-buffer-bit)
          (lwlgl.glfw:swap-buffers window)
          (lwlgl.glfw:poll-events))))

As funções OpenGL são resolvidas a partir do contexto atual pelo GLFW. `load-opengl` diferencia funções obrigatórias e opcionais; `gl-capabilities` e `gl-function-available-p` permitem caminhos condicionais por capacidade.

### Matemática, quaternions e primitivas de colisão

    (let* ((rotacao
             (lwlgl.math:quat-from-axis-angle
               (lwlgl.math:vec3 0 1 0)
               (lwlgl.math:degrees->radians 90)))
           (modelo
             (lwlgl.math:trs-mat4
               (lwlgl.math:vec3 3 0 -5)
               rotacao
               (lwlgl.math:vec3 1 1 1)))
           (inversa (lwlgl.math:mat4-inverse modelo)))
      (values modelo inversa))

A biblioteca também oferece AABBs e rays:

    (let ((caixa (lwlgl.math:aabb
                   (lwlgl.math:vec3 -1 -1 -1)
                   (lwlgl.math:vec3  1  1  1)))
          (raio (lwlgl.math:ray
                  (lwlgl.math:vec3 -5 0 0)
                  (lwlgl.math:vec3  1 0 0))))
      (lwlgl.math:ray-aabb-intersection raio caixa))
    ;; => 4.0, 6.0 como distâncias de entrada/saída

As consultas espaciais também incluem esferas, planos, interseção ray/esfera e frustum culling:

    (let* ((projecao (lwlgl.math:perspective-mat4
                        (lwlgl.math:degrees->radians 60)
                        (/ 16.0 9.0) 0.1 100.0))
           (view (lwlgl.math:look-at-mat4
                  (lwlgl.math:vec3 0 2 5)
                  (lwlgl.math:vec3 0 0 0)
                  (lwlgl.math:vec3 0 1 0)))
           (frustum (lwlgl.math:frustum-from-matrix
                     (lwlgl.math:mat4-mul projecao view)))
           (bounds (lwlgl.math:sphere (lwlgl.math:vec3 0 0 0) 1.5)))
      (lwlgl.math:frustum-intersects-sphere-p frustum bounds))

### Input stateful e mapas de ações

    (let* ((input (lwlgl.input:make-input-state window))
           (acoes (lwlgl.input:make-action-map)))
      (lwlgl.input:bind-action
        acoes :pular
        (lwlgl.input:key-binding lwlgl.glfw:key-space))

      (lwlgl.input:bind-axis
        acoes :horizontal
        (lwlgl.input:key-binding lwlgl.glfw:key-a)
        (lwlgl.input:key-binding lwlgl.glfw:key-d))

      (lwlgl.input:begin-input-frame input)
      (lwlgl.glfw:poll-events)

      (when (lwlgl.input:action-pressed-p acoes input :pular)
        (format t "Pular!~%"))

      (lwlgl.input:axis-value acoes input :horizontal))

Os mapas de ações ficam acima da API crua de teclado/mouse sem substituí-la. Bindings compostos permitem atalhos e alternativas, enquanto `BIND-AXIS2` fornece movimento estilo WASD/D-pad:

    (lwlgl.input:bind-action
      acoes :salvar
      (lwlgl.input:chord-binding
        (lwlgl.input:key-binding lwlgl.glfw:key-left-control)
        (lwlgl.input:key-binding lwlgl.glfw:key-s)))

    (lwlgl.input:bind-axis2
      acoes :movimento
      (lwlgl.input:key-binding lwlgl.glfw:key-a)
      (lwlgl.input:key-binding lwlgl.glfw:key-d)
      (lwlgl.input:key-binding lwlgl.glfw:key-s)
      (lwlgl.input:key-binding lwlgl.glfw:key-w)
      :normalize t)

    (multiple-value-bind (x y)
        (lwlgl.input:axis2-value acoes input :movimento)
      (mover-jogador x y))

### Assets, cache e reload

    (defparameter *assets*
      (lwlgl.assets:make-asset-manager
        :roots (list #P"assets/" #P"assets-compartilhados/")))

    (lwlgl.assets:register-asset-loader
      *assets* "glsl" #'lwlgl.assets:load-text-file)

    (defparameter *shader*
      (lwlgl.assets:load-asset *assets* "shaders/basic.glsl"))

    (lwlgl.assets:reload-changed-assets *assets*)

O cache usa o arquivo resolvido e o loader como chave. É possível recarregar automaticamente por data de modificação, invalidar assets específicos ou limpar todo o cache. `PRELOAD-ASSETS` faz carregamento em lote ordenado, `CACHED-ASSETS` expõe metadados do cache e listeners de reload recebem `(manager path value)` depois que `RELOAD-CHANGED-ASSETS` atualiza um arquivo.

### OBJ e upload para GPU

    (let ((mesh (lwlgl.obj:load-obj #P"models/nave.obj")))
      (format t "~D vértices, ~D triângulos~%"
              (lwlgl.obj:obj-mesh-vertex-count mesh)
              (lwlgl.obj:obj-mesh-triangle-count mesh))

      (lwlgl.gfx:with-gpu-mesh (gpu mesh)
        (lwlgl.gfx:draw-gpu-mesh gpu)))

O layout intercalado gerado pelo parser é:

    position.xyz | normal.xyz | texcoord.uv

`lwlgl/gfx` configura esses campos nos atributos OpenGL 0, 1 e 2.

### Includes GLSL e programas por arquivo

    (defparameter *programa*
      (lwlgl.gfx:make-program-from-files
        #P"shaders/world.vert"
        #P"shaders/world.frag"
        :include-dirs (list #P"shaders/include/")
        :defines '(("MAX_LIGHTS" . 8) "USE_FOG")))

O preprocessador expande `#include "arquivo"` e `#include <arquivo>` recursivamente, procura primeiro no diretório do arquivo atual, detecta ciclos e relata a pilha de includes em erros.

### Texturas a partir de imagens

    (multiple-value-bind (textura largura altura canais)
        (lwlgl.gfx:load-texture-2d
          #P"textures/albedo.png"
          :srgb t
          :generate-mipmaps t)
      (format t "Textura ~D: ~Dx~D, ~D canais~%"
              textura largura altura canais))

A memória decodificada pelo stb_image é liberada depois do upload para a GPU.

### Queries de GPU e fences

    (let ((query (lwlgl.opengl:make-query)))
      (unwind-protect
           (progn
             (lwlgl.opengl:with-query (query lwlgl.opengl:time-elapsed)
               (renderizar-cena))
             (lwlgl.opengl:query-result-ui64 query))
        (lwlgl.opengl:delete-query query)))

Para `GL_TIME_ELAPSED`, o resultado é dado em nanossegundos. As funções de sync permitem criar fences, aguardar no cliente e garantir cleanup com `with-fence`.

### Dispositivos OpenAL e captura

    (lwlgl.openal:openal-devices)
    (lwlgl.openal:default-openal-device)
    (lwlgl.openal:capture-devices)

    (lwlgl.openal:with-capture-device
        (device :sample-rate 44100
                :format lwlgl.openal:format-mono16
                :buffer-samples 8192)
      (lwlgl.openal:start-capture device)
      ;; ... aguarde/poll na aplicação ...
      (let ((disponiveis (lwlgl.openal:available-capture-samples device)))
        (when (plusp disponiveis)
          (lwlgl.openal:capture-samples device disponiveis)))
      (lwlgl.openal:stop-capture device))

A API permanece de baixo nível: a política de gravação, threads, buffers circulares e codecs pertence à aplicação.

### Bootstrap Vulkan por GLFW

    (when (lwlgl.glfw:vulkan-supported-p)
      (format t "Extensões necessárias: ~S~%"
              (lwlgl.glfw:required-vulkan-instance-extensions)))

Depois de a aplicação criar um `VkInstance`, `create-window-surface` conecta uma janela GLFW `NO_API` a um `VkSurfaceKHR`. LWLGL não impõe política de instance/device/swapchain.

### Timing e profiling

    (let ((clock (lwlgl.util:make-frame-clock))
          (profiler (lwlgl.util:make-profiler)))
      (lwlgl.util:with-profiled-section (profiler :update)
        (atualizar-mundo))

      (multiple-value-bind (dt elapsed fps)
          (lwlgl.util:tick-frame-clock clock)
        (declare (ignore elapsed))
        (format t "dt=~A fps=~A~%" dt fps))

      (lwlgl.util:profiler-report profiler))

O profiler agrega contagem, total, última amostra, mínimo, máximo e média por nome de seção. Filas de timers dirigidas por delta podem usar o mesmo clock de frame:

    (let ((timers (lwlgl.util:make-timer-queue)))
      (lwlgl.util:schedule-timer timers 2.0d0 #'abrir-porta)
      (lwlgl.util:schedule-repeating-timer timers 0.5d0 #'criar-particula)
      ;; uma vez por frame:
      (lwlgl.util:advance-timers timers dt))

As filas suportam pause/resume, cancelamento, escala global de tempo e limite de catch-up para timers repetitivos.

## Arquitetura sugerida

    aplicação
      -> lwlgl/core
           -> registro de módulos nativos
           -> memória CFFI / resolução de símbolos
      -> plataforma + dispositivos
           -> lwlgl/glfw
           -> lwlgl/input
           -> lwlgl/openal
      -> renderização
           -> lwlgl/opengl
           -> lwlgl/stb
           -> lwlgl/obj
           -> lwlgl/gfx
      -> computação / bootstrap gráfico explícito
           -> lwlgl/vulkan
           -> lwlgl/opencl
      -> suporte portátil
           -> lwlgl/math
           -> lwlgl/util
           -> lwlgl/assets
      -> renderer / arquitetura de jogo definidos pela aplicação

A fronteira é proposital: LWLGL fornece capacidades de baixo nível e pequenos utilitários reutilizáveis; scene graph, ECS, política do renderer, formatos de assets, threading, rede, física e gameplay continuam sendo decisões da aplicação.

## Sistemas

- `lwlgl/core` — plataforma, módulos nativos, memória, símbolos e diagnóstico;
- `lwlgl/math` — vetores, matrizes, quaternions, transforms, projeções, rays, AABBs, esferas, planos e frustums;
- `lwlgl/util` — clocks, timestep fixo, interpolação, timers determinísticos e profiling;
- `lwlgl/glfw` — janelas, contextos, monitores, dispositivos, callbacks e ponte Vulkan;
- `lwlgl/input` — estado por frame, bindings compostos, eixos 1D e eixos 2D;
- `lwlgl/assets` — raízes, loaders, preload, inspeção de cache, detecção de alterações e listeners de reload;
- `lwlgl/obj` — carregamento Wavefront OBJ;
- `lwlgl/opengl` — OpenGL carregado em runtime e helpers;
- `lwlgl/openal` — reprodução, WAV, streaming, descoberta e captura;
- `lwlgl/vulkan` — introspecção do loader/bootstrap;
- `lwlgl/opencl` — descoberta de plataforma/dispositivos de computação;
- `lwlgl/stb` — integração stb_image;
- `lwlgl/gfx` — helpers de integração gráfica entre módulos;
- `lwlgl/examples` — exemplos executáveis;
- `lwlgl/tests` — testes sem dispositivo.

## Documentação

A documentação em português do Brasil está em `doc-ptbr/`:

- `API.md` — referência compacta de subsistemas/API;
- `ARQUITETURA.md` — fronteiras dos módulos e modelo de extensão;
- `COMPILACAO.md` — ASDF, bibliotecas nativas e build do stb;
- `MIGRACAO.md` — migração do nome CLWJGL original e de versões anteriores do LWLGL.

A documentação em inglês está em `doc-en/`. Os arquivos em `examples/` também funcionam como documentação executável.

## Segurança de inicialização no Linux / Wayland

O LWLGL 0.3.2 desabilita por padrão o plugin GTK opcional do libdecor do GLFW em sessões Wayland detectadas. Isso evita uma classe de falhas do processo quando GTK/libdecor é carregado dentro do SBCL. Para sobrescrever o backend antes de iniciar o SBCL:

```bash
LWLGL_GLFW_PLATFORM=x11 sbcl       # força X11/XWayland no GLFW 3.4+
LWLGL_GLFW_PLATFORM=wayland sbcl   # força Wayland nativo no GLFW 3.4+
LWLGL_GLFW_LIBDECOR=prefer sbcl    # reativa libdecor explicitamente
```

Inspecione o estado com `(lwlgl.glfw:glfw-diagnostics)`.

## Limitações atuais

### SBCL e traps nativos de ponto flutuante

O LWLGL 0.3.2 protege `lwlgl.glfw:with-glfw` contra traps de ponto flutuante do SBCL que podem ser disparados dentro do sistema de janelas ou do driver gráfico. Ao integrar diretamente outra API multimídia nativa, envolva esse escopo com `lwlgl.core:with-native-floating-point-environment`.

A versão 0.4.1 ainda é uma biblioteca de baixo nível em estágio inicial. Vulkan fornece bootstrap/introspecção do loader em vez de bindings Vulkan completos gerados; OpenCL está concentrado em descoberta, não em toda a API de comandos; o parser OBJ implementa o subconjunto geométrico comum e ainda não cobre MTL/materiais, geração de normals por smoothing groups ou todas as extensões de fornecedores; `lwlgl/gfx` é uma camada de conveniência, não um renderer; stb_image exige a compilação do shim incluído; e APIs nativas dependem das bibliotecas fornecidas pelo sistema ou pela aplicação.

Direções futuras incluem bindings gerados para Vulkan/OpenGL/OpenAL/OpenCL, debug output e indirect/multi-draw no OpenGL, cursores/ícones de janela, abstrações de streaming de áudio, MTL e glTF, fontes/texto, gerenciamento de mappings de controles, empacotamento nativo, CI em várias implementações Lisp e testes executáveis em dispositivos gráficos/áudio reais.

## Licença

MIT. Consulte `LICENSE`.
