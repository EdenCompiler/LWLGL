# Arquitetura do LWLGL

## Objetivo

LWLGL é uma biblioteca de bindings e runtime, não uma engine. Ela torna APIs nativas de multimídia/computação utilizáveis em Common Lisp preservando controle explícito sobre recursos, loop principal e arquitetura da aplicação.

Camadas principais:

1. **Core runtime** — plataforma, módulos nativos, memória CFFI e diagnóstico.
2. **Bindings crus** — constantes, structs e ABI em C.
3. **Loaders de capacidades** — resolução dinâmica onde necessário, especialmente OpenGL/Vulkan.
4. **Helpers Lisp finos** — escopo de recursos, matemática, temporização, profiling, input, assets e parsing de formatos.
5. **Integração opcional** — `lwlgl/gfx` compõe OpenGL, stb_image e OBJ sem impor um renderer.

## Sistemas ASDF

```text
lwlgl/core
├── lwlgl/util
├── lwlgl/glfw ──┬── lwlgl/input
│                └── lwlgl/opengl ─── lwlgl/math
├── lwlgl/openal
├── lwlgl/vulkan
├── lwlgl/opencl
└── lwlgl/stb ──────────────┐
                            ├── lwlgl/gfx
lwlgl/obj ─── lwlgl/math ───┘
lwlgl/assets      (arquivos/cache portável)
lwlgl/math        (Lisp puro)
lwlgl             (sistema agregador)
```

Cada sistema pode ser carregado separadamente. `lwlgl/bindings` agrega o runtime e os bindings nativos; `lwlgl/extras` agrega helpers Lisp opcionais; e `lwlgl/all` carrega ambos junto do gerador. Durante o ciclo de compatibilidade 0.5, `lwlgl` continua equivalente a `lwlgl/all`.

## OpenGL

`DEFINE-GL-FUNCTION` registra funções resolvidas via `glfwGetProcAddress` e metadados introspectáveis de cada assinatura. O contexto precisa estar atual antes de:

```lisp
(lwlgl.opengl:load-opengl)
```

O loader diferencia funções obrigatórias e opcionais. `CREATE-GL-CAPABILITIES` cria uma tabela de dispatch associada ao contexto atual e `WITH-GL-CAPABILITIES` a seleciona dinamicamente. `LOAD-OPENGL` preserva a API anterior e ativa o novo objeto.

## Callbacks GLFW

Um callback CFFI estático recebe cada evento nativo e despacha para listas de handlers Lisp associadas ao endereço da janela.

- `SET-*-HANDLER`: substitui os handlers daquele evento.
- `ADD-*-HANDLER`: adiciona outro consumidor.
- `REMOVE-*-HANDLER`: remove um consumidor.

Assim, `lwlgl/input` pode acompanhar estado sem bloquear callbacks da aplicação.

## Recursos

O LWLGL mantém handles nativos visíveis. Macros de escopo reduzem vazamentos:

- `WITH-GLFW`, `WITH-WINDOW`, `WITH-OPENAL`, `WITH-IMAGE`
- `WITH-NATIVE-BUFFER`, `WITH-FOREIGN-ARRAY`
- macros `WITH-BOUND-*` do OpenGL

`NATIVE-BUFFER` também registra capacidade em bytes, tamanho de elemento, alinhamento, ownership, estado read-only e lifetime do buffer pai. Views/slices emprestados não liberam a memória do owner. `WITH-NATIVE-ARENA` agrupa várias alocações sob um lifetime determinístico.

## Matemática

`lwlgl/math` é Lisp puro. Matrizes 4×4 são arrays de 16 `single-float` em ordem column-major, compatíveis com upload direto ao OpenGL.

A camada fornece fundamentos de runtime, não uma engine de física: vetores, matrizes, quaternions, transform/projection, AABBs, rays, planos, esferas e frustums. Frustums são extraídos de matrizes de clip no estilo OpenGL e oferecem testes de ponto/esfera/AABB adequados para culling sem impor ownership da cena.

## Temporização

`FRAME-CLOCK` fornece delta, tempo acumulado, contagem de frames e estimativa de FPS. `FIXED-STEP` implementa simulação em passo fixo com limite de catch-up para evitar spiral of death.

`TIMER-QUEUE` é dirigida por delta: não cria thread nem faz sleep. A aplicação a avança com o delta do frame ou da simulação. Timers one-shot e repetitivos suportam cancelamento, pause/resume por timer, pausa e escala global da fila e catch-up limitado, preservando testabilidade determinística.

## Composição de input

`lwlgl/input` mantém o estado dos dispositivos separado da interpretação de ações. `KEY-BINDING` e `MOUSE-BINDING` são descritores folha; `CHORD-BINDING` e `ANY-BINDING` os compõem recursivamente sem instalar callbacks nativos adicionais. `BIND-AXIS2` armazena quatro conjuntos direcionais e retorna X/Y como múltiplos valores, evitando uma dependência do sistema de input de volta para `lwlgl/math`.

## Estratégia de expansão

`lwlgl/bindgen` lê especificações S-expression declarativas com reader evaluation desabilitada, valida nomes/assinaturas, calcula fingerprint determinístico e emite source reproduzível. `bindings/opengl-bootstrap.sexp` é o primeiro manifesto fixado. Importadores de registries oficiais podem gerar essa representação intermediária sem transformar o core em um monólito.


## Assets, formatos e integração

`lwlgl/assets` não depende do renderer: resolve nomes contra raízes de busca, despacha loaders por extensão, mantém cache, suporta preload ordenado em lote e inspeção dos metadados do cache, além de detectar alterações por timestamp para fluxos de desenvolvimento. Listeners de reload notificam a aplicação depois do refresh por polling sem transformar o módulo em um watcher nativo do sistema operacional.

`lwlgl/obj` converte um subconjunto focado de geometria Wavefront em uma representação indexada/intercalada. `lwlgl/gfx` é a ponte opcional para upload de OBJ, `#include` GLSL, programas baseados em arquivos e texturas decodificadas pelo stb. Essa separação evita transformar os bindings em uma engine/renderizador.

## Crescimento das APIs nativas

GLFW inclui a ponte mínima para Vulkan (suporte, extensões de instance e criação de surface). Queries/fences OpenGL são capacidades opcionais. Enumeração e captura OpenAL permanecem operações ALC explícitas e de baixo nível.
