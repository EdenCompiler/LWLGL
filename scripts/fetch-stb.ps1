$ErrorActionPreference = "Stop"
$Root = Resolve-Path "$PSScriptRoot\.."
$Dest = Join-Path $Root "native\vendor\stb_image.h"
New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
$Url = "https://raw.githubusercontent.com/nothings/stb/master/stb_image.h"
Invoke-WebRequest -Uri $Url -OutFile $Dest
Write-Host "stb_image.h salvo em: $Dest"
