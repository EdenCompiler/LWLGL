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

Cada sistema pode ser carregado separadamente.

## OpenGL

`DEFINE-GL-FUNCTION` registra funções resolvidas via `glfwGetProcAddress`. O contexto precisa estar atual antes de:

```lisp
(lwlgl.opengl:load-opengl)
```

O loader diferencia funções obrigatórias e opcionais. Funções opcionais ausentes não fazem o carregamento inteiro falhar.

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

## Matemática

`lwlgl/math` é Lisp puro. Matrizes 4×4 são arrays de 16 `single-float` em ordem column-major, compatíveis com upload direto ao OpenGL.

## Temporização

`FRAME-CLOCK` fornece delta, tempo acumulado, contagem de frames e estimativa de FPS. `FIXED-STEP` implementa simulação em passo fixo com limite de catch-up para evitar spiral of death.

## Estratégia de expansão

A arquitetura foi organizada para receber bindings gerados de registries oficiais (Khronos etc.) sem transformar o core em um monólito. Helpers manuais devem continuar pequenos, auditáveis e opcionais.


## Assets, formatos e integração

`lwlgl/assets` não depende do renderer: resolve nomes contra raízes de busca, despacha loaders por extensão, mantém cache e detecta alterações por timestamp para fluxos de desenvolvimento. É polling explícito, não um watcher nativo do sistema operacional.

`lwlgl/obj` converte um subconjunto focado de geometria Wavefront em uma representação indexada/intercalada. `lwlgl/gfx` é a ponte opcional para upload de OBJ, `#include` GLSL, programas baseados em arquivos e texturas decodificadas pelo stb. Essa separação evita transformar os bindings em uma engine/renderizador.

## Crescimento das APIs nativas

GLFW inclui a ponte mínima para Vulkan (suporte, extensões de instance e criação de surface). Queries/fences OpenGL são capacidades opcionais. Enumeração e captura OpenAL permanecem operações ALC explícitas e de baixo nível.
