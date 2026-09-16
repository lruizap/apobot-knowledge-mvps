param([string]$Project = "mvp-minimo")
$ErrorActionPreference = "Stop"
$compose = Join-Path $PSScriptRoot "..\$Project\docker-compose.yml"
if (!(Test-Path $compose)) { throw "No existe $compose" }
docker compose -f $compose config --quiet
if ($LASTEXITCODE -ne 0) { throw "Compose inválido: $Project" }
Write-Host "Compose válido: $Project"
