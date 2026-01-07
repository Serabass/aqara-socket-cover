# Upload firmware for ESP32
# Uses automatic reset via upload_flags in platformio.ini

$pioPath = "$env:USERPROFILE\.platformio\penv\Scripts\platformio.exe"

if (-not (Test-Path $pioPath)) {
    $pioPath = Get-Command platformio -ErrorAction SilentlyContinue
    if ($pioPath) {
        $pioPath = $pioPath.Source
    } else {
        Write-Host "ERROR: PlatformIO not found!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Uploading firmware to ESP32..." -ForegroundColor Cyan
& $pioPath run --environment esp32dev

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nUpload failed! Trying manual reset..." -ForegroundColor Yellow
    Write-Host "Run: .\upload_with_reset.ps1" -ForegroundColor Cyan
    Write-Host "Or manually:" -ForegroundColor Yellow
    Write-Host "  1. Press and HOLD BOOT button" -ForegroundColor Cyan
    Write-Host "  2. Press and RELEASE RESET button" -ForegroundColor Cyan
    Write-Host "  3. Release BOOT button" -ForegroundColor Cyan
    Write-Host "  4. Run upload again" -ForegroundColor Cyan
}

exit $LASTEXITCODE
