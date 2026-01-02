# Скрипт для установки драйверов ESP32
# Запусти от имени администратора!

Write-Host "=== Поиск ESP32 устройств ===" -ForegroundColor Cyan

# Ищем ESP32 устройства
$esp32Devices = Get-PnpDevice | Where-Object {
    $_.InstanceId -like "*VID_303A*" -or 
    $_.FriendlyName -like "*ESP32*" -or
    $_.FriendlyName -like "*USB JTAG*"
}

if ($esp32Devices) {
    Write-Host "`nНайдены ESP32 устройства:" -ForegroundColor Green
    $esp32Devices | Format-Table -AutoSize Status, FriendlyName, InstanceId
} else {
    Write-Host "ESP32 устройства не найдены" -ForegroundColor Yellow
}

# Ищем CH340/CH9102
Write-Host "`n=== Поиск CH340/CH9102 адаптеров ===" -ForegroundColor Cyan
$ch340Devices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*CH340*" -or $_.FriendlyName -like "*CH9102*"
}

if ($ch340Devices) {
    Write-Host "Найдены USB-to-Serial адаптеры:" -ForegroundColor Green
    $ch340Devices | Format-Table -AutoSize Status, FriendlyName, InstanceId
} else {
    Write-Host "CH340/CH9102 адаптеры не найдены" -ForegroundColor Yellow
}

Write-Host "`n=== Решение ===" -ForegroundColor Cyan

# Проверяем, какой тип ESP32
$hasNativeUSB = $esp32Devices | Where-Object {$_.InstanceId -like "*VID_303A*"}
$hasCH340 = $ch340Devices | Where-Object {$_.Status -ne "OK"}

if ($hasNativeUSB) {
    Write-Host "Обнаружен ESP32 с нативным USB (ESP32-S3/C3)" -ForegroundColor Yellow
    Write-Host "Нужно установить драйверы ESP32 USB:" -ForegroundColor White
    Write-Host "  1. Скачай ESP32 USB драйверы:" -ForegroundColor Cyan
    Write-Host "     https://github.com/espressif/usb-serial-esp32/releases" -ForegroundColor White
    Write-Host "  2. Или установи через PlatformIO:" -ForegroundColor Cyan
    Write-Host "     pio platform install espressif32" -ForegroundColor White
    Write-Host "  3. Или используй ESP32 Flash Download Tool" -ForegroundColor Cyan
}

if ($hasCH340) {
    Write-Host "`nОбнаружены CH340/CH9102 адаптеры без драйверов" -ForegroundColor Yellow
    Write-Host "Установи драйверы CH340:" -ForegroundColor White
    Write-Host "  http://www.wch.cn/downloads/CH341SER_EXE.html" -ForegroundColor Cyan
    Write-Host "Или CH9102:" -ForegroundColor White
    Write-Host "  http://www.wch.cn/downloads/CH9102DRV_EXE.html" -ForegroundColor Cyan
}

Write-Host "`n=== После установки драйверов ===" -ForegroundColor Cyan
Write-Host "1. Перезагрузи компьютер" -ForegroundColor Yellow
Write-Host "2. Отключи и подключи ESP32 заново" -ForegroundColor Yellow
Write-Host "3. Проверь: pio device list" -ForegroundColor Yellow

