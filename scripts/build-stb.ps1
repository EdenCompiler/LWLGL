$ErrorActionPreference = "Stop"
$Root = Resolve-Path "$PSScriptRoot\.."
$Out = Join-Path $Root "native\build"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$Source = Join-Path $Root "native\lwlgl_stb.c"
$Target = Join-Path $Out "lwlgl_stb.dll"
if (Get-Command clang -ErrorAction SilentlyContinue) {
    clang -O2 -shared $Source -o $Target
} elseif (Get-Command gcc -ErrorAction SilentlyContinue) {
    gcc -O2 -shared $Source -o $Target
} else {
    throw "clang ou gcc não encontrado no PATH."
}
Write-Host "Biblioteca criada em: $Target"
