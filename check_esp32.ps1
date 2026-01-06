# Quick ESP32 check
$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== ESP32 devices ===" -ForegroundColor Cyan
$esp32 = Get-PnpDevice | Where-Object { 
    $_.InstanceId -like "*VID_303A*" -or 
    $_.InstanceId -like "*VID_10C4*" -or 
    $_.InstanceId -like "*VID_1A86*" -or
    $_.FriendlyName -like "*ESP*" -or
    $_.FriendlyName -like "*CH340*" -or
    $_.FriendlyName -like "*CP210*"
}
if ($esp32) {
    $esp32 | Format-Table Status, FriendlyName, InstanceId -AutoSize
} else {
    Write-Host "ESP32 devices not found" -ForegroundColor Red
}

Write-Host "`n=== Problem devices ===" -ForegroundColor Yellow
$problems = Get-PnpDevice | Where-Object { 
    $_.Status -ne "OK" -and (
        $_.FriendlyName -like "*Unknown*" -or
        $_.InstanceId -like "*VID_303A*" -or
        $_.InstanceId -like "*VID_10C4*" -or
        $_.InstanceId -like "*VID_1A86*"
    )
}
if ($problems) {
    $problems | Format-Table Status, Class, FriendlyName, InstanceId -AutoSize
} else {
    Write-Host "No problem devices found" -ForegroundColor Green
}

Write-Host "`n=== COM ports ===" -ForegroundColor Cyan
$ports = [System.IO.Ports.SerialPort]::GetPortNames()
if ($ports) {
    $ports | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "No COM ports found!" -ForegroundColor Red
}
