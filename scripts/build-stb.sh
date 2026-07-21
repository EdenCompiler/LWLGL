#!/usr/bin/env sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/native/build"
mkdir -p "$OUT"
case "$(uname -s)" in
  Darwin) cc -O2 -fPIC -dynamiclib "$ROOT/native/lwlgl_stb.c" -o "$OUT/liblwlgl_stb.dylib" ;;
  Linux)  cc -O2 -fPIC -shared "$ROOT/native/lwlgl_stb.c" -o "$OUT/liblwlgl_stb.so" -lm ;;
  *) echo "Plataforma não suportada por este script. Use build-stb.ps1 no Windows." >&2; exit 1 ;;
esac
echo "Biblioteca criada em: $OUT"
