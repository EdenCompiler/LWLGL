# Native memory, providers, and capabilities

Native APIs operate on addresses and lifetimes that the Lisp garbage collector cannot infer. LWLGL keeps those rules visible while providing deterministic cleanup.

## Native buffers

A `NATIVE-BUFFER` records its pointer, element type, length, byte capacity, alignment, ownership, read-only state, cursor position, and limit.

```lisp
(lwlgl.core:with-native-buffer (buffer :float 4 :initial-element 0.0)
  (lwlgl.core:buffer-put buffer 1.0)
  (lwlgl.core:buffer-put buffer 2.0)
  (lwlgl.core:flip-native-buffer buffer)
  (list (lwlgl.core:buffer-get buffer)
        (lwlgl.core:buffer-get buffer)))
```

`BUFFER-REF` and `BUFFER-SET` use absolute indices. `BUFFER-GET` and `BUFFER-PUT` use and advance the cursor. `CLEAR-NATIVE-BUFFER`, `FLIP-NATIVE-BUFFER`, and `REWIND-NATIVE-BUFFER` have the familiar NIO-style meanings.

Views and slices borrow memory from a parent buffer. They must not outlive that parent.

## Choosing an allocation strategy

Use the shortest lifetime that fits:

- `WITH-MEMORY-STACK` and `STACK-MALLOC`/`STACK-CALLOC` for temporary native arguments;
- `WITH-NATIVE-BUFFER` for one scoped owned allocation;
- `WITH-NATIVE-ARENA` for several owned allocations released together;
- `MEM-ALLOC`/`MEM-CALLOC` and `MEM-FREE` for storage retained across calls.

```lisp
(lwlgl.core:with-memory-stack (stack)
  (let ((major (lwlgl.core:stack-calloc :int 1 :stack stack)))
    (native-call (lwlgl.core:native-buffer-pointer major))
    (lwlgl.core:buffer-ref major 0)))
```

Stack buffers are invalid after their frame is popped. Do not store their pointers in a native object that survives the scope.

## Strings and addresses

`MEM-UTF8` creates a null-terminated UTF-8 buffer by default. Free it when it is not arena-owned:

```lisp
(let ((name (lwlgl.core:mem-utf8 "u_model")))
  (unwind-protect
       (native-call (lwlgl.core:native-buffer-pointer name))
    (lwlgl.core:mem-free name)))
```

`MEM-ADDRESS` returns an integer address at the current or supplied element position. Native calls normally need `NATIVE-BUFFER-POINTER`, while integer addresses are useful for diagnostics and offset calculations.

## Function providers

A `FUNCTION-PROVIDER` maps a native command name to a function pointer. Loaders use providers to isolate platform-specific symbol resolution:

```lisp
(let ((provider
        (lwlgl.core:make-function-provider
         :name :application
         :resolver #'resolve-command)))
  (lwlgl.core:get-function-address provider "commandName" :required t))
```

## Capability tables

An `API-CAPABILITIES` object stores resolved function pointers and advertised features. Query it before using optional commands:

```lisp
(when (lwlgl.core:capability-supported-p capabilities :some-extension)
  ...)

(when (lwlgl.opengles:gl-function-available-p "glClear" capabilities)
  ...)
```

Use `WITH-CAPABILITIES` when an API dispatches through a dynamically selected context. Keep capability ownership aligned with the native context, instance, or device that produced it.

## Callbacks

Native code may retain a callback pointer after the registering call returns. `CALLBACK-RESOURCE` keeps the Lisp function and native pointer associated until `FREE-CALLBACK` or `WITH-CALLBACK` releases them. The application must still unregister a callback from the native API before releasing a pointer the native side may call again.
