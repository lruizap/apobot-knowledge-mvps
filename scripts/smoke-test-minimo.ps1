param([int]$Port = 5087)
$ErrorActionPreference = "Stop"
$health = Invoke-RestMethod "http://localhost:$Port/api/health"
if (!$health.connected) { throw "La base de datos no está conectada" }
if ([int64]$health.manuals -lt 1) { throw "No hay manual cargado" }
if ([int64]$health.chunks -lt 11) { throw "Se esperaban al menos 11 fragmentos" }
$answer = Invoke-RestMethod "http://localhost:$Port/api/chat" -Method Post -ContentType "application/json" -Body '{"message":"¿Qué valor debe tener KG+ del eje S?"}'
if ($answer.answer -notmatch '340') { throw "La prueba KG+ no devolvió 340" }
Write-Host "Smoke test mínimo correcto: manual=$($health.manuals), chunks=$($health.chunks)"
