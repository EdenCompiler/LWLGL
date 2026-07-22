# Migração do CLWJGL 0.1 para LWLGL 0.2

A biblioteca foi renomeada para **LWLGL — Lightweight Lisp Game Library**.

## Renomeações mecânicas

- `clwjgl.asd` → `lwlgl.asd`
- `:clwjgl` → `:lwlgl`
- `:clwjgl/core` → `:lwlgl/core` (mesmo padrão para os demais sistemas)
- `clwjgl.core` → `lwlgl.core` (mesmo padrão para os pacotes)
- `clwjgl_stb` → `lwlgl_stb`

Na maior parte do código, uma substituição global de `clwjgl` por `lwlgl`, preservando maiúsculas/minúsculas, resolve a migração.

## Callbacks GLFW

Os setters continuam existindo, mas internamente os callbacks agora aceitam múltiplos handlers. As novas funções `ADD-*-HANDLER` e `REMOVE-*-HANDLER` permitem que camadas como `lwlgl/input` coexistam com callbacks da aplicação.

## Novos sistemas

- `lwlgl/math`
- `lwlgl/util`
- `lwlgl/input`

O sistema principal `:lwlgl` carrega todos automaticamente.


## Do LWLGL 0.3 para 0.4

A 0.4 é aditiva para o uso normal da 0.3. Os nomes públicos existentes e as fronteiras entre subsistemas continuam disponíveis.

Novas APIs:

- `lwlgl/math`: `PLANE`, `SPHERE`, interseção ray/esfera, overlap esfera/AABB, `FRUSTUM-FROM-MATRIX` e consultas de ponto/esfera/AABB contra frustum.
- `lwlgl/util`: `TIMER-QUEUE` determinística com timers one-shot/repetitivos, cancelamento, pause/resume, escala de tempo e catch-up limitado.
- `lwlgl/input`: `CHORD-BINDING`, `ANY-BINDING` e eixos digitais 2D com `BIND-AXIS2` / `AXIS2-VALUE`.
- `lwlgl/assets`: `PRELOAD-ASSETS`, `CACHED-ASSETS` e listeners de reload adicionáveis/removíveis.

O sistema agregador `:lwlgl` continua carregando todos os módulos. `lwlgl/tests` agora também depende de `lwlgl/input` para testar bindings compostos sem abrir janela.

## Do LWLGL 0.2 para 0.3

A 0.3 é aditiva para o uso normal da 0.2. Os novos sistemas opcionais são `lwlgl/assets`, `lwlgl/obj` e `lwlgl/gfx`; o sistema agregador `:lwlgl` os carrega automaticamente. Os nomes públicos existentes foram preservados.

O loader OpenGL ganhou entry points opcionais de queries/sync; continue usando checks de capacidade ao suportar contextos antigos. Os novos helpers de matemática, action maps, assets, OBJ, captura e GLFW/Vulkan não substituem as APIs de baixo nível.

## Do LWLGL 0.5 para 1.0

A versão 1.0 torna os nomes no estilo LWJGL a API canônica de baixo nível. Os helpers amigáveis existentes continuam disponíveis, mas novos bindings devem:

- importar um pacote versionado, como `lwlgl.opengl.gl33`, `lwlgl.glfw.glfw34`, `lwlgl.openal.al11`, `lwlgl.opencl.cl30` ou `lwlgl.vulkan.vk14`;
- chamar entry points checked com o prefixo da API (`GL-*`, `GLFW-*`, `AL-*`, `CL-*`, `VK-*`, `EGL-*`);
- usar entry points raw orientados a ponteiros com `N` inicial somente quando necessário;
- obter constantes `+API-NOME+` dos pacotes versionados;
- criar e vincular capabilities explicitamente para APIs com dispatch por contexto/dispositivo;
- usar `WITH-MEMORY-STACK` para argumentos temporários e `MEM-ALLOC`/`MEM-FREE` para memória nativa retida.

OpenGL ES e EGL são novos sistemas independentes, `lwlgl/opengles` e `lwlgl/egl`. A cobertura dos registries ainda é curada na 1.0; consulte os predicates de capabilities antes de chamadas opcionais.
