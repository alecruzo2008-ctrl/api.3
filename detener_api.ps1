$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$PidFile = Join-Path $ProjectRoot ".api.pid"
$PythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path -LiteralPath $PidFile)) {
    Write-Host "No encuentro el archivo PID; la API no parece estar iniciada por iniciar_api.ps1."
    exit 0
}

$serverId = 0
[void][int]::TryParse((Get-Content -Raw -LiteralPath $PidFile).Trim(), [ref]$serverId)
if ($serverId -le 0) {
    Remove-Item -LiteralPath $PidFile -Force
    throw "El archivo .api.pid no contiene un PID válido."
}

$processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $serverId" -ErrorAction SilentlyContinue
if (-not $processInfo) {
    Remove-Item -LiteralPath $PidFile -Force
    Write-Host "La API ya estaba detenida."
    exit 0
}

$expectedPython = (Resolve-Path -LiteralPath $PythonExe).Path
if ($processInfo.ExecutablePath -ne $expectedPython -or $processInfo.CommandLine -notmatch 'uvicorn app\.main:app') {
    throw "El PID guardado no corresponde al servidor de este proyecto; por seguridad no lo detuve. Revisa .api.pid."
}

Stop-Process -Id $serverId
Remove-Item -LiteralPath $PidFile -Force
Write-Host "API detenida (PID $serverId)."
