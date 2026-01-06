# Полная диагностика ESP32 устройств
# Запусти от имени администратора для полной информации!

Write-Host "=== ДИАГНОСТИКА ESP32 ===" -ForegroundColor Cyan
Write-Host ""

# Проверяем все USB устройства
Write-Host "=== Все USB устройства ===" -ForegroundColor Yellow
$allUSB = Get-PnpDevice | Where-Object {
    $_.Class -eq "USB" -or 
    $_.Class -eq "Ports" -or
    $_.Class -eq "System" -or
    $_.FriendlyName -like "*USB*"
} | Sort-Object Status, FriendlyName

if ($allUSB) {
    $allUSB | Format-Table -AutoSize Status, Class, FriendlyName, InstanceId | Out-String | Write-Host
} else {
    Write-Host "USB устройства не найдены" -ForegroundColor Red
}

# Ищем ESP32 по VID/PID
Write-Host "`n=== Поиск ESP32 по VID/PID ===" -ForegroundColor Yellow
$esp32Devices = Get-PnpDevice | Where-Object {
    $_.InstanceId -like "*VID_303A*" -or  # Espressif VID
    $_.InstanceId -like "*VID_10C4*" -or  # Silicon Labs (CP210x)
    $_.InstanceId -like "*VID_1A86*" -or  # WCH (CH340)
    $_.InstanceId -like "*VID_2E8A*"      # Raspberry Pi (может быть на некоторых платах)
}

if ($esp32Devices) {
    Write-Host "Найдены потенциальные ESP32 устройства:" -ForegroundColor Green
    $esp32Devices | Format-Table -AutoSize Status, FriendlyName, InstanceId | Out-String | Write-Host
} else {
    Write-Host "ESP32 устройства не найдены по VID/PID" -ForegroundColor Red
}

# Ищем по названию
Write-Host "`n=== Поиск по названию ===" -ForegroundColor Yellow
$byName = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*ESP*" -or
    $_.FriendlyName -like "*JTAG*" -or
    $_.FriendlyName -like "*Serial*" -or
    $_.FriendlyName -like "*CH340*" -or
    $_.FriendlyName -like "*CH9102*" -or
    $_.FriendlyName -like "*CP210*" -or
    $_.FriendlyName -like "*Silicon*"
}

if ($byName) {
    Write-Host "Найдены устройства по названию:" -ForegroundColor Green
    $byName | Format-Table -AutoSize Status, FriendlyName, InstanceId | Out-String | Write-Host
} else {
    Write-Host "Устройства по названию не найдены" -ForegroundColor Red
}

# Ищем проблемные устройства (без драйверов)
Write-Host "`n=== Проблемные устройства (без драйверов) ===" -ForegroundColor Yellow
$problemDevices = Get-PnpDevice | Where-Object {
    $_.Status -ne "OK" -and (
        $_.FriendlyName -like "*Unknown*" -or
        $_.FriendlyName -like "*Неизвестное*" -or
        $_.Class -eq "Unknown" -or
        $_.InstanceId -like "*VID_303A*" -or
        $_.InstanceId -like "*VID_10C4*" -or
        $_.InstanceId -like "*VID_1A86*"
    )
}

if ($problemDevices) {
    Write-Host "НАЙДЕНЫ УСТРОЙСТВА БЕЗ ДРАЙВЕРОВ!" -ForegroundColor Red
    $problemDevices | Format-Table -AutoSize Status, Class, FriendlyName, InstanceId | Out-String | Write-Host
    
    # Определяем тип устройства
    foreach ($device in $problemDevices) {
        if ($device.InstanceId -like "*VID_303A*") {
            Write-Host "`n>>> Это ESP32 с нативным USB (ESP32-S3/C3)!" -ForegroundColor Cyan
            Write-Host "    Нужны драйверы ESP32 USB Serial" -ForegroundColor White
        } elseif ($device.InstanceId -like "*VID_1A86*") {
            Write-Host "`n>>> Это CH340 адаптер!" -ForegroundColor Cyan
            Write-Host "    Нужны драйверы CH340" -ForegroundColor White
        } elseif ($device.InstanceId -like "*VID_10C4*") {
            Write-Host "`n>>> Это CP210x адаптер!" -ForegroundColor Cyan
            Write-Host "    Нужны драйверы CP210x" -ForegroundColor White
        }
    }
} else {
    Write-Host "Проблемных устройств не найдено" -ForegroundColor Green
}

# Проверяем COM-порты
Write-Host "`n=== COM-порты ===" -ForegroundColor Yellow
$comPorts = [System.IO.Ports.SerialPort]::GetPortNames()
if ($comPorts) {
    Write-Host "Найдено COM-портов: $($comPorts.Count)" -ForegroundColor Green
    $comPorts | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "COM-портов не найдено!" -ForegroundColor Red
}

# Проверяем через WMI
Write-Host "`n=== Проверка через WMI ===" -ForegroundColor Yellow
try {
    $wmiPorts = Get-WmiObject Win32_SerialPort -ErrorAction SilentlyContinue
    if ($wmiPorts) {
        Write-Host "Найдено портов через WMI: $($wmiPorts.Count)" -ForegroundColor Green
        $wmiPorts | Format-Table -AutoSize DeviceID, Description, Name | Out-String | Write-Host
    } else {
        Write-Host "Портов через WMI не найдено" -ForegroundColor Red
    }
} catch {
    Write-Host "Ошибка при проверке WMI: $_" -ForegroundColor Red
}

# Итоговые рекомендации
Write-Host "`n=== РЕКОМЕНДАЦИИ ===" -ForegroundColor Cyan

if (-not $esp32Devices -and -not $byName -and -not $problemDevices) {
    Write-Host "`nБЛЯДЬ, Windows вообще не видит устройство!" -ForegroundColor Red
    Write-Host "Возможные причины:" -ForegroundColor Yellow
    Write-Host "  1. Кабель не поддерживает передачу данных (только зарядка)" -ForegroundColor White
    Write-Host "  2. USB порт не работает" -ForegroundColor White
    Write-Host "  3. Плата неисправна" -ForegroundColor White
    Write-Host "  4. Нужно нажать кнопку BOOT/RESET на плате" -ForegroundColor White
    Write-Host "`nЧто делать:" -ForegroundColor Yellow
    Write-Host "  1. Попробуй другой USB кабель (обязательно с передачей данных!)" -ForegroundColor White
    Write-Host "  2. Попробуй другой USB порт" -ForegroundColor White
    Write-Host "  3. Нажми и удерживай BOOT, затем нажми RESET, отпусти BOOT" -ForegroundColor White
    Write-Host "  4. Проверь, что плата вообще включается (светодиоды горят?)" -ForegroundColor White
} elseif ($problemDevices) {
    Write-Host "`nУстройство найдено, но драйверы не установлены!" -ForegroundColor Yellow
    Write-Host "`nУстановка драйверов:" -ForegroundColor Cyan
    
    $hasESP32Native = $problemDevices | Where-Object {$_.InstanceId -like "*VID_303A*"}
    $hasCH340 = $problemDevices | Where-Object {$_.InstanceId -like "*VID_1A86*"}
    $hasCP210x = $problemDevices | Where-Object {$_.InstanceId -like "*VID_10C4*"}
    
    if ($hasESP32Native) {
        Write-Host "`n>>> Для ESP32 с нативным USB:" -ForegroundColor Yellow
        Write-Host "  1. Скачай драйверы: https://github.com/espressif/usb-serial-esp32/releases" -ForegroundColor White
        Write-Host "  2. Или через PlatformIO: pio platform install espressif32" -ForegroundColor White
        Write-Host "  3. Или установи ESP-IDF (включает драйверы)" -ForegroundColor White
    }
    
    if ($hasCH340) {
        Write-Host "`n>>> Для CH340:" -ForegroundColor Yellow
        Write-Host "  Скачай: http://www.wch.cn/downloads/CH341SER_EXE.html" -ForegroundColor White
    }
    
    if ($hasCP210x) {
        Write-Host "`n>>> Для CP210x:" -ForegroundColor Yellow
        Write-Host "  Скачай: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers" -ForegroundColor White
    }
    
    Write-Host "`nПосле установки:" -ForegroundColor Cyan
    Write-Host "  1. Перезагрузи компьютер" -ForegroundColor White
    Write-Host "  2. Отключи и подключи ESP32 заново" -ForegroundColor White
    Write-Host "  3. Запусти этот скрипт снова для проверки" -ForegroundColor White
} else {
    Write-Host "`nВсё вроде нормально, но COM-портов нет. Странно..." -ForegroundColor Yellow
    Write-Host "Попробуй:" -ForegroundColor Cyan
    Write-Host "  1. Отключи и подключи ESP32 заново" -ForegroundColor White
    Write-Host "  2. Проверь через: pio device list" -ForegroundColor White
}

Write-Host "`n=== КОНЕЦ ДИАГНОСТИКИ ===" -ForegroundColor Cyan
