#!/usr/bin/env sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DEST="$ROOT/native/vendor/stb_image.h"
mkdir -p "$(dirname "$DEST")"
URL="https://raw.githubusercontent.com/nothings/stb/master/stb_image.h"
if command -v curl >/dev/null 2>&1; then
  curl -fL "$URL" -o "$DEST"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$DEST" "$URL"
else
  echo "É necessário curl ou wget para obter stb_image.h." >&2
  exit 1
fi
echo "stb_image.h salvo em: $DEST"
