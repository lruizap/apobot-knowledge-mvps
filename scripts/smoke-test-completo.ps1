param([int]$Port = 5077)
$ErrorActionPreference = "Stop"
$health = Invoke-RestMethod "http://localhost:$Port/api/knowledge/health"
if (!$health.exists) { throw "El directorio documental no existe" }
if ([int64]$health.documents -lt 1) { throw "No hay documentos indexados; ejecutar /api/knowledge/index primero" }
Write-Host "Smoke test completo correcto: documents=$($health.documents), chunks=$($health.chunks)"
