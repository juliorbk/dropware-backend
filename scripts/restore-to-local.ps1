$ErrorActionPreference = "Stop"
$backupFile = Join-Path $PSScriptRoot "..\dropware_backup.sql" | Resolve-Path -Relative

if (-not (Test-Path $backupFile)) {
    Write-Host "❌ No se encuentra $backupFile. Ejecutá primero dump-from-render.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "⏳ Restaurando $backupFile en Docker local..." -ForegroundColor Cyan

Get-Content $backupFile | docker exec -i dropware_db psql -U dropware_user -d dropware_db

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Restauración completada" -ForegroundColor Green
} else {
    Write-Host "❌ Error al restaurar" -ForegroundColor Red
    exit 1
}
