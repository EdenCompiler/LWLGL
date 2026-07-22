# Convenções de API no estilo LWJGL

O LWLGL 1.0 adota a organização de baixo nível do LWJGL com nomes e ownership explícitos em Common Lisp.

## Pacotes versionados

Escolha o pacote correspondente ao nível da API alvo: `lwlgl.opengl.gl33`, `lwlgl.opengl.gl46`, `lwlgl.opengles.gles32`, `lwlgl.glfw.glfw34`, `lwlgl.openal.al11`, `lwlgl.opencl.cl30`, `lwlgl.vulkan.vk14` ou `lwlgl.egl.egl15`.

Pacotes posteriores reexportam os comandos das versões anteriores. Isso organiza o source, mas não substitui a verificação das capabilities reais do contexto ou dispositivo.

## Chamadas checked e raw

Entry points checked mantêm o prefixo da API. Entry points raw, orientados a ponteiros, acrescentam `N`:

```lisp
(lwlgl.opengl.gl33:gl-clear
 lwlgl.opengl.gl33:+gl-color-buffer-bit+)

(lwlgl.opengl.gl33:ngl-clear
 lwlgl.opengl.gl33:+gl-color-buffer-bit+)
```

Prefira chamadas checked no código da aplicação. Use as raw ao implementar overloads, trabalhar com ponteiros já validados ou reproduzir exatamente a ABI C.

Constantes usam `+` e o prefixo da API, como `+GL-DEPTH-TEST+` e `+GLFW-KEY-ESCAPE+`.

## Bindings e helpers

Chamadas nativas e constantes ficam nos pacotes versionados. Helpers Lisp pequenos permanecem no pacote do subsistema:

```lisp
(lwlgl.opengl.gl33:gl-bind-buffer
 lwlgl.opengl.gl33:+gl-array-buffer+ buffer)

(lwlgl.opengl:upload-floats
 lwlgl.opengl.gl33:+gl-array-buffer+ vertices
 lwlgl.opengl.gl33:+gl-static-draw+)
```

## Dispatch por contexto ou dispositivo

Crie capabilities OpenGL somente depois de tornar o contexto correto current. Vulkan associa capabilities a instances/devices; OpenAL e OpenCL usam providers para resolver os comandos disponíveis.

Não reutilize uma capability em um contexto ou dispositivo não relacionado. Para dispatch dinâmico, use `WITH-CAPABILITIES`.

Os nomes amigáveis antigos continuam disponíveis para migração gradual. Novo código de baixo nível deve preferir os pacotes versionados usados nos exemplos.
