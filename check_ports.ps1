# Скрипт для проверки COM-портов и установки драйверов
# Запусти от имени администратора!

Write-Host "=== Проверка COM-портов ===" -ForegroundColor Cyan

# Проверяем все COM-порты
$ports = Get-PnpDevice -Class Ports | Where-Object {$_.Status -eq "OK"}
Write-Host "`nНайдено COM-портов: $($ports.Count)" -ForegroundColor Green
$ports | Format-Table -AutoSize Status, FriendlyName

# Проверяем проблемные устройства
Write-Host "`n=== Проблемные устройства (без драйверов) ===" -ForegroundColor Yellow
$problemDevices = Get-PnpDevice | Where-Object {
    ($_.FriendlyName -like "*CH340*" -or $_.FriendlyName -like "*CH9102*" -or $_.FriendlyName -like "*CP210*") -and
    $_.Status -ne "OK"
}

if ($problemDevices) {
    $problemDevices | Format-Table -AutoSize Status, FriendlyName, InstanceId
    Write-Host "`nЭти устройства требуют установки драйверов!" -ForegroundColor Red
    Write-Host "Скачай драйверы с:" -ForegroundColor Yellow
    Write-Host "  CH340: http://www.wch.cn/downloads/CH341SER_EXE.html" -ForegroundColor White
    Write-Host "  CH9102: http://www.wch.cn/downloads/CH9102DRV_EXE.html" -ForegroundColor White
} else {
    Write-Host "Проблемных устройств не найдено" -ForegroundColor Green
}

# Проверяем через PlatformIO
Write-Host "`n=== Проверка через PlatformIO ===" -ForegroundColor Cyan
pio device list

Write-Host "`n=== Инструкция ===" -ForegroundColor Cyan
Write-Host "1. Если видишь 'Unknown Ports' - нужно установить драйверы" -ForegroundColor Yellow
Write-Host "2. Скачай драйверы с официального сайта WCH" -ForegroundColor Yellow
Write-Host "3. Установи драйверы и перезагрузи компьютер" -ForegroundColor Yellow
Write-Host "4. Отключи и подключи ESP32 заново" -ForegroundColor Yellow
Write-Host "5. Запусти этот скрипт снова для проверки" -ForegroundColor Yellow

