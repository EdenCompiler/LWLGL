# Guia da API LWLGL 0.5

## Core

```lisp
(lwlgl.core:add-native-search-path #P"./native/")
(lwlgl.core:print-runtime-report)
```

Buffers alinhados suportam slices emprestados e arenas de lifetime compartilhado:

```lisp
(lwlgl.core:with-native-buffer (buffer :float 16 :alignment 16)
  (lwlgl.core:fill-native-buffer
   (lwlgl.core:slice-native-buffer buffer 4 8) 1.0))

(lwlgl.core:with-native-arena (arena)
  (let ((vertices (lwlgl.core:arena-alloc arena :float 1024)))
    ...))
```

## Matemática

```lisp
(let* ((view (lwlgl.math:look-at-mat4
              (lwlgl.math:vec3 0 1 4)
              (lwlgl.math:vec3 0 0 0)
              (lwlgl.math:vec3 0 1 0)))
       (projection (lwlgl.math:perspective-mat4
                    (lwlgl.math:degrees->radians 60)
                    (/ 16.0 9.0) 0.1 100.0)))
  (lwlgl.math:mat4-mul projection view))
```

## Quaternions, inversão e geometria

```lisp
(let* ((q (lwlgl.math:quat-from-axis-angle
           (lwlgl.math:vec3 0 1 0)
           (lwlgl.math:degrees->radians 90)))
       (m (lwlgl.math:trs-mat4
           (lwlgl.math:vec3 0 0 -4) q
           (lwlgl.math:vec3 1 1 1))))
  (lwlgl.math:mat4-inverse m))
```

Também há `AABB`, `RAY`, interseção ray/AABB, projeção e unprojection de pontos para picking e bounds.

A 0.4 adiciona planos, esferas de bounding, interseção ray/esfera e frustum culling:

```lisp
(let* ((projecao (lwlgl.math:perspective-mat4
                  (lwlgl.math:degrees->radians 60)
                  (/ 16.0 9.0) 0.1 100.0))
       (view (lwlgl.math:look-at-mat4
              (lwlgl.math:vec3 0 2 5)
              (lwlgl.math:vec3 0 0 0)
              (lwlgl.math:vec3 0 1 0)))
       (frustum (lwlgl.math:frustum-from-matrix
                 (lwlgl.math:mat4-mul projecao view)))
       (bounds (lwlgl.math:sphere (lwlgl.math:vec3 0 0 0) 2.0)))
  (lwlgl.math:frustum-intersects-sphere-p frustum bounds))
```

`FRUSTUM-INTERSECTS-AABB-P`, `FRUSTUM-CONTAINS-POINT-P`, `SPHERE-INTERSECTS-AABB-P` e `RAY-SPHERE-INTERSECTION` cobrem consultas comuns de visibilidade e picking.

## Profiling

`MAKE-PROFILER`, `WITH-PROFILED-SECTION` e `PROFILER-REPORT` agregam contagem, total, última amostra, mínimo, máximo e média por seção nomeada.

## Janela e GLFW

```lisp
(lwlgl.glfw:with-glfw ()
  (lwlgl.glfw:with-window (window 1280 720 "Minha aplicação")
    (lwlgl.glfw:make-context-current window)
    ...))
```

Callbacks podem ser compostos com `ADD-*-HANDLER` e removidos com `REMOVE-*-HANDLER`.

Monitores e gamepads:

```lisp
(lwlgl.glfw:get-monitors)
(lwlgl.glfw:monitor-video-mode (lwlgl.glfw:primary-monitor))
(lwlgl.glfw:gamepad-state lwlgl.glfw:joystick-1)
```

## Input stateful

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

## Temporização

```lisp
(let ((clock (lwlgl.util:make-frame-clock)))
  (multiple-value-bind (dt elapsed fps)
      (lwlgl.util:tick-frame-clock clock)
    ...))
```

`MAKE-FIXED-STEP` + `ADVANCE-FIXED-STEP` ajudam a separar simulação fixa da renderização.

### Timers determinísticos

```lisp
(let ((timers (lwlgl.util:make-timer-queue :max-catch-up 4)))
  (lwlgl.util:schedule-timer timers 1.0d0 #'mostrar-mensagem)
  (defparameter *timer-spawn*
    (lwlgl.util:schedule-repeating-timer timers 0.25d0 #'criar-particula))

  (lwlgl.util:advance-timers timers dt)
  (lwlgl.util:pause-timer timers *timer-spawn*)
  (lwlgl.util:resume-timer timers *timer-spawn*)
  (lwlgl.util:cancel-timer timers *timer-spawn*))
```

`TIMER-QUEUE-TIME-SCALE` e `TIMER-QUEUE-PAUSED-P` aceitam `SETF`. Timers repetitivos usam catch-up limitado para impedir rajadas ilimitadas de callbacks depois de um frame muito longo.

## Mapas de ações de input

```lisp
(let ((acoes (lwlgl.input:make-action-map)))
  (lwlgl.input:bind-action
   acoes :pular (lwlgl.input:key-binding lwlgl.glfw:key-space))
  (lwlgl.input:bind-axis
   acoes :horizontal
   (lwlgl.input:key-binding lwlgl.glfw:key-a)
   (lwlgl.input:key-binding lwlgl.glfw:key-d)))
```

Ações aceitam múltiplos bindings; eixos digitais combinam bindings negativo/positivo.

A 0.4 adiciona bindings compostos e eixos 2D:

```lisp
(lwlgl.input:bind-action
 acoes :salvar
 (lwlgl.input:chord-binding
  (lwlgl.input:key-binding lwlgl.glfw:key-left-control)
  (lwlgl.input:key-binding lwlgl.glfw:key-s)))

(lwlgl.input:bind-action
 acoes :confirmar
 (lwlgl.input:any-binding
  (lwlgl.input:key-binding lwlgl.glfw:key-enter)
  (lwlgl.input:key-binding lwlgl.glfw:key-space)))

(lwlgl.input:bind-axis2
 acoes :movimento
 (lwlgl.input:key-binding lwlgl.glfw:key-a)
 (lwlgl.input:key-binding lwlgl.glfw:key-d)
 (lwlgl.input:key-binding lwlgl.glfw:key-s)
 (lwlgl.input:key-binding lwlgl.glfw:key-w)
 :normalize t)

(multiple-value-bind (x y)
    (lwlgl.input:axis2-value acoes input :movimento)
  ...)
```

`CHORD-BINDING` exige que todos os bindings filhos estejam ativos. `ANY-BINDING` aceita qualquer filho. `:NORMALIZE T` evita que o movimento diagonal fique mais rápido que o movimento cardinal.

## Assets e hot reload de desenvolvimento

`lwlgl/assets` oferece raízes de busca, loaders por extensão, cache, invalidação e detecção de arquivos alterados por timestamp. A 0.4 também oferece preload em lote, inspeção de metadados do cache e listeners de reload.

```lisp
(let ((assets (lwlgl.assets:make-asset-manager :roots (list #P"assets/"))))
  (lwlgl.assets:register-asset-loader assets "glsl" #'lwlgl.assets:load-text-file)
  (lwlgl.assets:load-asset assets "shaders/basic.glsl")
  (lwlgl.assets:preload-assets assets
                              '("shaders/world.vert" "shaders/world.frag"))
  (lwlgl.assets:add-asset-reload-listener
   assets
   (lambda (manager path value)
     (declare (ignore manager value))
     (format t "Recarregado: ~A~%" path)))
  (lwlgl.assets:reload-changed-assets assets)
  (lwlgl.assets:cached-assets assets))
```

`CACHED-ASSETS` retorna plists com `:PATH`, `:WRITE-DATE` e `:LOADER`. Os listeners são chamados depois que `RELOAD-CHANGED-ASSETS` recarrega uma entrada em cache.

## Wavefront OBJ

`lwlgl/obj` faz parsing de posições, UVs, normals, índices negativos e polígonos triangulados em leque, produzindo vértices indexados deduplicados e bounds. O layout é `position.xyz | normal.xyz | texcoord.uv`.

## OpenGL

Fluxo obrigatório:

```lisp
(lwlgl.glfw:make-context-current window)
(lwlgl.opengl:load-opengl)
```

A 0.3 inclui buffers/sub-data, VAOs, instancing, uniform blocks, shaders, texturas, mipmaps, framebuffers, renderbuffers, readback de pixels e estado de renderização.

```lisp
(let ((program (lwlgl.opengl:make-program vertex-source fragment-source)))
  (lwlgl.opengl:with-program (program)
    (lwlgl.opengl:set-uniform-mat4
     (lwlgl.opengl:gl-get-uniform-location program "uMVP")
     mvp)))
```

### Queries de GPU e fences

As APIs opcionais incluem query objects para timing/occlusion e sync fences (`MAKE-QUERY`, `WITH-QUERY`, `MAKE-FENCE`, `WAIT-FENCE`, `WITH-FENCE`).

## Integração gráfica

`lwlgl/gfx` adiciona preprocessamento recursivo de `#include` GLSL, programas a partir de arquivos, upload de imagens stb para texturas OpenGL e upload/draw de meshes OBJ em VAO/VBO/EBO.

## OpenAL e WAV

```lisp
(lwlgl.openal:with-openal ()
  (multiple-value-bind (source buffer)
      (lwlgl.openal:play-wav #P"som.wav")
    (unwind-protect
         (lwlgl.openal:wait-source source)
      (lwlgl.openal:delete-source source)
      (lwlgl.openal:delete-buffer buffer))))
```

Também há filas de buffers para streaming, posição/velocidade/gain/pitch, orientação do listener, enumeração de dispositivos e captura ALC de baixo nível.

## Ponte GLFW/Vulkan

`VULKAN-SUPPORTED-P`, `REQUIRED-VULKAN-INSTANCE-EXTENSIONS` e `CREATE-WINDOW-SURFACE` cobrem a integração de janela necessária antes de a aplicação administrar instance/device/swapchain.

## Vulkan

```lisp
(lwlgl.vulkan:vulkan-loader-info)
```

Retorna versão do loader, extensões de instância e layers. Ainda é bootstrap/discovery, não cobertura Vulkan completa.

## OpenCL

```lisp
(lwlgl.opencl:opencl-report)
```

O relatório inclui plataformas e dispositivos com compute units, clock, work-group size, memória global/local, driver e extensões.

## stb_image

Após compilar o shim opcional:

```lisp
(lwlgl.core:add-native-search-path #P"./native/build/")
(lwlgl.stb:image-info #P"texture.png")
(lwlgl.stb:load-image-from-memory bytes :channels 4)
(lwlgl.stb:load-hdr-image #P"environment.hdr")
```
