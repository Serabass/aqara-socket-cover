# Upload firmware with automatic ESP32 reset
# This script resets ESP32 and then uploads firmware

param(
    [string]$Port = "COM3"
)

Write-Host "=== ESP32 Upload with Reset ===" -ForegroundColor Cyan

# First, reset ESP32
Write-Host "`nStep 1: Resetting ESP32 into download mode..." -ForegroundColor Yellow
& "$PSScriptRoot\reset_esp32.ps1" -Port $Port

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Failed to reset ESP32. Upload aborted." -ForegroundColor Red
    exit 1
}

# Wait a bit for ESP32 to stabilize
Start-Sleep -Seconds 1

# Now upload
Write-Host "`nStep 2: Uploading firmware..." -ForegroundColor Yellow
$pioPath = "$env:USERPROFILE\.platformio\penv\Scripts\platformio.exe"

if (-not (Test-Path $pioPath)) {
    Write-Host "ERROR: PlatformIO not found at $pioPath" -ForegroundColor Red
    Write-Host "Trying to find platformio..." -ForegroundColor Yellow
    $pioPath = Get-Command platformio -ErrorAction SilentlyContinue
    if (-not $pioPath) {
        Write-Host "ERROR: PlatformIO not found in PATH" -ForegroundColor Red
        exit 1
    }
    $pioPath = $pioPath.Source
}

& $pioPath run --target upload --environment esp32dev 2>&1 | Tee-Object -Variable output

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
} else {
    Write-Host "`n=== FAILED ===" -ForegroundColor Red
    Write-Host "If you see 'Wrong boot mode', try:" -ForegroundColor Yellow
    Write-Host "  1. Press and HOLD BOOT button" -ForegroundColor Cyan
    Write-Host "  2. Press and RELEASE RESET button" -ForegroundColor Cyan
    Write-Host "  3. Release BOOT button" -ForegroundColor Cyan
    Write-Host "  4. Run: .\upload_with_reset.ps1" -ForegroundColor Cyan
}

exit $LASTEXITCODE
