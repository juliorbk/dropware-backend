$ErrorActionPreference = "Stop"
$sqlFile = Join-Path $PSScriptRoot "seed-demo-data.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ No se encuentra $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "⏳ Cargando datos de demostración en el contenedor visco_db_dev (5434)..." -ForegroundColor Cyan

Get-Content $sqlFile | docker exec -i visco_db_dev psql -U visco_admin -d visco_db -v ON_ERROR_STOP=1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Datos de demostración cargados correctamente" -ForegroundColor Green
} else {
    Write-Host "❌ Error al cargar los datos" -ForegroundColor Red
    exit 1
}
