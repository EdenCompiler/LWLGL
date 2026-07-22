# Guia dos exemplos

Os exemplos são documentação executável do LWLGL 1.0:

```bash
sbcl --script scripts/run-examples.lisp toolbox native-memory capabilities
sbcl --script scripts/run-examples.lisp --smoke spinning-cube triangle audio
```

`--smoke` limita exemplos interativos para validação automática.

## Catálogo

| Nome no runner | Função | Demonstração |
| --- | --- | --- |
| `toolbox` | `toolbox-demo` | matemática, timers, profiling e OBJ |
| `native-memory` | `native-memory-demo` | buffers, stack e UTF-8 |
| `capabilities` | `capabilities-demo` | providers, capabilities e pacotes versionados |
| `system-info` | `system-info` | monitores, Vulkan e OpenCL |
| `opengl-info` | `opengl-info` | contexto oculto e comandos resolvidos |
| `egl-info` | `egl-info` | inicialização do display EGL |
| `hello-window` | `hello-window` | janela e clear loop mínimos |
| `triangle` | `triangle` | shaders, VAO, VBO e atributos |
| `spinning-cube` | `spinning-cube` | renderização 3D indexada e matrizes MVP |
| `textured-quad` | `textured-quad` | textura procedural, UVs e sampler |
| `offscreen-framebuffer` | `offscreen-framebuffer` | framebuffer e readback de pixels |
| `instanced-triangles` | `instanced-triangles` | atributos por instância |
| `input` | `input-demo` | input por frame e timing |
| `audio` | `audio-tone` | reprodução PCM via OpenAL |
| `positional-audio` | `positional-audio` | source espacial móvel e listener |
| `vulkan-readiness` | `vulkan-readiness` | janela sem API e requisitos de instance |

## Cubo giratório

`examples/spinning-cube.lisp` cria um contexto OpenGL 3.3, envia posições/cores para um VBO, índices para um EBO e associa tudo a um VAO. Depth testing resolve as superfícies visíveis.

A cada frame, o exemplo combina rotações X/Y, uma view transladada e uma projeção perspective ajustada ao framebuffer. `SET-UNIFORM-MAT4` envia a matriz MVP column-major, e `GL-DRAW-ELEMENTS` desenha 36 índices.

Para teste automatizado:

```lisp
(lwlgl.examples:spinning-cube :max-frames 2)
```

Sem `:MAX-FRAMES`, Escape ou o botão de fechar encerra o loop. No Linux, `LWLGL_GLFW_PLATFORM=x11` pode ser usado quando o endpoint Wayland da sessão não está acessível.
