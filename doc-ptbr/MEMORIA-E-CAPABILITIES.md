# Memória nativa, providers e capabilities

APIs nativas trabalham com endereços e lifetimes que o garbage collector não consegue inferir. O LWLGL mantém essas regras visíveis e oferece cleanup determinístico.

## Buffers nativos

`NATIVE-BUFFER` registra ponteiro, tipo, comprimento, capacidade em bytes, alinhamento, ownership, estado read-only, posição e limite.

```lisp
(lwlgl.core:with-native-buffer (buffer :float 4 :initial-element 0.0)
  (lwlgl.core:buffer-put buffer 1.0)
  (lwlgl.core:flip-native-buffer buffer)
  (lwlgl.core:buffer-get buffer))
```

`BUFFER-REF`/`BUFFER-SET` usam índices absolutos. `BUFFER-GET`/`BUFFER-PUT` avançam o cursor. Views e slices emprestam memória e não podem sobreviver ao buffer pai.

## Estratégias de alocação

- `WITH-MEMORY-STACK` para argumentos temporários;
- `WITH-NATIVE-BUFFER` para uma alocação owned com escopo;
- `WITH-NATIVE-ARENA` para várias alocações liberadas juntas;
- `MEM-ALLOC`/`MEM-CALLOC` e `MEM-FREE` para memória retida entre chamadas.

```lisp
(lwlgl.core:with-memory-stack (stack)
  (let ((value (lwlgl.core:stack-calloc :int 1 :stack stack)))
    (native-call (lwlgl.core:native-buffer-pointer value))))
```

Ponteiros da stack ficam inválidos quando o frame termina. `MEM-UTF8` cria um buffer UTF-8 terminado em zero; libere-o com `MEM-FREE` quando ele não pertence a uma arena.

## Providers e capabilities

`FUNCTION-PROVIDER` transforma o nome de um comando nativo em um ponteiro. `API-CAPABILITIES` guarda ponteiros resolvidos e features anunciadas.

Consulte `CAPABILITY-SUPPORTED-P` ou o predicate específico da API antes de comandos opcionais. Mantenha a capability junto do contexto, instance ou device que a produziu.

## Callbacks

`CALLBACK-RESOURCE` mantém a função Lisp e o ponteiro nativo associados até `FREE-CALLBACK` ou `WITH-CALLBACK`. A aplicação ainda deve remover o callback da API nativa antes de liberar um ponteiro que possa ser chamado novamente.
