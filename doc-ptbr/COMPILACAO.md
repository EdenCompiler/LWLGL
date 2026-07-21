# Compilação e dependências nativas

## Dependências Lisp

- ASDF/UIOP
- CFFI

```lisp
(ql:quickload :cffi)
(asdf:load-asd #P"/caminho/lwlgl/lwlgl.asd")
(asdf:load-system :lwlgl)
```

Os exemplos ficam no sistema ASDF separado `lwlgl/examples`:

```lisp
(asdf:load-system :lwlgl/examples)
(lwlgl.examples:toolbox-demo)
```

Como alternativa, `(load #P"quickstart.lisp")` carrega a biblioteca principal e também o sistema de exemplos.

## Bibliotecas nativas

Instale apenas os módulos necessários:

- GLFW 3 para janelas/entrada/contexto;
- driver OpenGL para renderização OpenGL;
- OpenAL/OpenAL Soft para áudio;
- loader Vulkan para o módulo Vulkan;
- ICD loader OpenCL para o módulo OpenCL.

Diretórios personalizados podem ser adicionados assim:

```lisp
(lwlgl.core:add-native-search-path #P"./native/")
```

## Shim do stb_image

`native/lwlgl_stb.c` depende do header oficial `stb_image.h` em:

```text
native/vendor/stb_image.h
```

Caso o header upstream não esteja incluído no pacote, com acesso à internet execute:

```bash
./scripts/fetch-stb.sh
./scripts/build-stb.sh
```

No Windows PowerShell:

```powershell
./scripts/fetch-stb.ps1
./scripts/build-stb.ps1
```

Depois:

```lisp
(lwlgl.core:add-native-search-path #P"./native/build/")
```

O módulo STB é opcional e não impede o uso dos demais módulos.

## Testes

```lisp
(asdf:test-system :lwlgl/tests)
```

Os testes centrais não exigem GPU, janela ou dispositivo de áudio.

## SBCL: `FLOATING-POINT-INVALID-OPERATION` no GLFW ou nos drivers gráficos

O SBCL normalmente habilita traps para operação de ponto flutuante inválida, overflow e divisão por zero. Alguns caminhos nativos do sistema de janelas/driver OpenGL podem executar instruções de ponto flutuante que marcam essas exceções de hardware mesmo quando a chamada nativa pode continuar normalmente. Desde o LWLGL 0.3.2, a biblioteca mascara esses traps durante o escopo dinâmico de `LWLGL.GLFW:WITH-GLFW` e restaura o modo de ponto flutuante anterior ao sair.

Aplicações que chamam bibliotecas multimídia nativas fora de `WITH-GLFW` podem usar explicitamente:

```lisp
(lwlgl.core:with-native-floating-point-environment ()
  ;; chamadas nativas/driver
  ...)
```

Para diagnóstico no SBCL:

```lisp
(sb-int:get-floating-point-modes)
```
