# Full USB device check
$ErrorActionPreference = "Continue"

Write-Host "=== All USB devices (first 50) ===" -ForegroundColor Cyan
$usb = Get-PnpDevice | Where-Object { $_.Class -eq "USB" } | Select-Object -First 50
if ($usb) {
    $usb | Format-Table Status, FriendlyName -AutoSize
} else {
    Write-Host "No USB devices found" -ForegroundColor Red
}

Write-Host "`n=== Devices with problems ===" -ForegroundColor Yellow
$bad = Get-PnpDevice | Where-Object { $_.Status -ne "OK" } | Select-Object -First 30
if ($bad) {
    $bad | Format-Table Status, Class, FriendlyName -AutoSize
} else {
    Write-Host "No problem devices" -ForegroundColor Green
}

Write-Host "`n=== All Ports class devices ===" -ForegroundColor Cyan
$ports = Get-PnpDevice | Where-Object { $_.Class -eq "Ports" }
if ($ports) {
    $ports | Format-Table Status, FriendlyName, InstanceId -AutoSize
} else {
    Write-Host "No Ports devices found" -ForegroundColor Red
}

Write-Host "`n=== COM ports via .NET ===" -ForegroundColor Cyan
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()
if ($comPorts) {
    $comPorts | ForEach-Object { Write-Host "  COM: $_" }
} else {
    Write-Host "No COM ports found!" -ForegroundColor Red
}

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Yellow
if (-not $comPorts) {
    Write-Host "Windows does not see your ESP32 at all!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible reasons:" -ForegroundColor Cyan
    Write-Host "  1. Cable is charge-only (no data transfer)" -ForegroundColor White
    Write-Host "  2. USB port is broken" -ForegroundColor White
    Write-Host "  3. ESP32 board is broken" -ForegroundColor White
    Write-Host "  4. Need to press BOOT button" -ForegroundColor White
    Write-Host ""
    Write-Host "What to do:" -ForegroundColor Cyan
    Write-Host "  1. Try another USB cable (must support data!)" -ForegroundColor White
    Write-Host "  2. Try another USB port" -ForegroundColor White
    Write-Host "  3. Press and hold BOOT, press RESET, release BOOT" -ForegroundColor White
    Write-Host "  4. Check if board has power (LEDs lit?)" -ForegroundColor White
}
