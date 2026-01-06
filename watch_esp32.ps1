# Watch for ESP32 connection
# Press Ctrl+C to stop

Write-Host "=== ESP32 Connection Watcher ===" -ForegroundColor Cyan
Write-Host "Watching for ESP32 devices..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Gray

$lastCount = 0

while ($true) {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames()
    $portCount = $ports.Count
    
    $esp32Devices = Get-PnpDevice | Where-Object { 
        $_.InstanceId -like "*VID_303A*" -or 
        $_.InstanceId -like "*VID_10C4*" -or 
        $_.InstanceId -like "*VID_1A86*" -or
        $_.FriendlyName -like "*ESP*" -or
        $_.FriendlyName -like "*CH340*" -or
        $_.FriendlyName -like "*CP210*"
    }
    
    if ($portCount -ne $lastCount -or $esp32Devices) {
        Clear-Host
        Write-Host "=== ESP32 Connection Watcher ===" -ForegroundColor Cyan
        Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')`n" -ForegroundColor Gray
        
        Write-Host "COM Ports: $portCount" -ForegroundColor $(if ($portCount -gt 0) { "Green" } else { "Red" })
        if ($ports) {
            $ports | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
        }
        
        Write-Host "`nESP32 Devices:" -ForegroundColor Cyan
        if ($esp32Devices) {
            $esp32Devices | Format-Table Status, FriendlyName, InstanceId -AutoSize
        } else {
            Write-Host "  Not found" -ForegroundColor Red
        }
        
        $lastCount = $portCount
    }
    
    Start-Sleep -Seconds 2
}
