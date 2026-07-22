# Fluxos gráficos práticos

Este guia relaciona os exemplos do LWLGL com tarefas comuns de aplicações. Todos permanecem na versão 1.0.0.

## Texturas procedurais

`examples/textured-quad.lisp` cria um checkerboard em um array Lisp de bytes, o expõe temporariamente como memória nativa e faz upload com `CREATE-TEXTURE-2D`.

O OpenGL copia os pixels durante `GL-TEX-IMAGE-2D`, então o array CFFI temporário pode ser liberado depois da chamada. O handle da textura continua owned pela aplicação e é removido explicitamente.

```bash
sbcl --script scripts/run-examples.lisp textured-quad
```

O exemplo também cobre VBO intercalado de posição/UV, EBO, filtro nearest, texture unit, sampler uniform e desenho indexado.

## Renderização offscreen e readback

`examples/offscreen-framebuffer.lisp` cria um contexto oculto e um framebuffer RGBA, limpa o target e copia o pixel central para um vetor Lisp.

```bash
sbcl --script scripts/run-examples.lisp offscreen-framebuffer
```

Esse fluxo é a base para screenshots, selection buffers, thumbnails, testes de GPU e render-to-texture:

```text
criar textura + framebuffer
            ↓
bind → renderizar → sincronizar
            ↓
ler pixels ou amostrar a textura depois
            ↓
unbind e cleanup explícito
```

Readback síncrono em todo frame pode bloquear o pipeline. Aplicações maiores devem migrar para staging/PBO assíncrono quando esses comandos estiverem na superfície dos bindings.

## Renderização 3D indexada

`examples/spinning-cube.lisp` demonstra VBO, EBO, VAO, depth test, perspective ajustada ao resize, composição model/view/projection, uniform e `GL-DRAW-ELEMENTS`.

As matrizes são column-major e podem ser enviadas sem transpose:

```lisp
(let ((mvp (lwlgl.math:mat4-mul
            projection (lwlgl.math:mat4-mul view model))))
  (lwlgl.opengl:set-uniform-mat4 location mvp))
```

## Preparação de janela Vulkan

`examples/vulkan-readiness.lisp` cobre o fluxo prático permitido pela camada Vulkan atual:

- verifica loader e ICD pelo GLFW;
- cria uma janela `GLFW_NO_API`;
- consulta versão, extensions e layers;
- compara as extensions de surface exigidas pelo GLFW;
- informa a presença da validation layer Khronos.

```bash
sbcl --script scripts/run-examples.lisp vulkan-readiness
```

O exemplo termina antes de criar a instance. O LWLGL 1.0 fornece introspecção/bootstrap Vulkan, mas ainda não toda a superfície gerada de instance, device, swapchain e comandos de renderização.

## Outros sistemas nativos

`opengl-info` valida resolução de comandos, `egl-info` valida o display EGL, `system-info` combina monitores/Vulkan/OpenCL e `positional-audio` aplica o mesmo modelo de recursos explícitos a uma source OpenAL móvel.

```bash
sbcl --script scripts/run-examples.lisp --smoke textured-quad spinning-cube positional-audio
sbcl --script scripts/run-examples.lisp offscreen-framebuffer vulkan-readiness
```
