$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$PythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
$PidFile = Join-Path $ProjectRoot ".api.pid"
$LogFile = Join-Path $ProjectRoot "api.log"
$ErrorLog = Join-Path $ProjectRoot "api-error.log"

if (-not (Test-Path -LiteralPath $PythonExe)) {
    throw "No encuentro el entorno virtual. Primero ejecuta: python -m venv .venv y luego instala requirements.txt."
}

if (Test-Path -LiteralPath $PidFile) {
    $savedPid = 0
    [void][int]::TryParse((Get-Content -Raw -LiteralPath $PidFile).Trim(), [ref]$savedPid)
    if ($savedPid -gt 0 -and (Get-Process -Id $savedPid -ErrorAction SilentlyContinue)) {
        Write-Host "La API ya está iniciada (PID $savedPid)."
        Write-Host "Panel web: http://127.0.0.1:8000/"
        Write-Host "Swagger:   http://127.0.0.1:8000/docs"
        exit 0
    }
    Remove-Item -LiteralPath $PidFile -Force
}

$server = Start-Process `
    -FilePath $PythonExe `
    -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000") `
    -WorkingDirectory $ProjectRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $LogFile `
    -RedirectStandardError $ErrorLog `
    -PassThru

Start-Sleep -Seconds 2
if ($server.HasExited) {
    Write-Host "La API no pudo iniciar. Revisa api-error.log y api.log."
    if (Test-Path -LiteralPath $ErrorLog) { Get-Content -Tail 20 -LiteralPath $ErrorLog }
    exit 1
}

Set-Content -LiteralPath $PidFile -Value $server.Id -NoNewline
Write-Host "API iniciada en segundo plano (PID $($server.Id))."
Write-Host "Panel web: http://127.0.0.1:8000/"
Write-Host "Swagger:   http://127.0.0.1:8000/docs"
Write-Host "Para detenerla ejecuta: .\detener_api.ps1"
