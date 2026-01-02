# PowerShell скрипт для поиска MQTT топика
# Требует: Install-Module -Name MQTT -Scope CurrentUser

param(
    [string]$Broker = "192.168.88.13",
    [int]$Port = 30081,
    [string]$User = "mqtt",
    [string]$Password = "mqtt",
    [int]$Timeout = 30
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "🔎 Поиск MQTT топика для сенсора мощности розетки" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Брокер: ${Broker}:${Port}" -ForegroundColor White
Write-Host "Пользователь: ${User}`n" -ForegroundColor White

# Проверяем наличие модуля MQTT
if (-not (Get-Module -ListAvailable -Name MQTT)) {
    Write-Host "❌ Модуль MQTT не установлен!" -ForegroundColor Red
    Write-Host "Установи его командой:" -ForegroundColor Yellow
    Write-Host "  Install-Module -Name MQTT -Scope CurrentUser" -ForegroundColor White
    Write-Host "`nИли используй Python скрипт: python find_mqtt_topic.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "💡 Используй Python скрипт для более детального поиска:" -ForegroundColor Yellow
Write-Host "   python find_mqtt_topic.py`n" -ForegroundColor White

# Альтернатива: используй mosquitto_sub если установлен
$mosquittoPath = Get-Command mosquitto_sub -ErrorAction SilentlyContinue

if ($mosquittoPath) {
    Write-Host "✅ Найден mosquitto_sub, используем его..." -ForegroundColor Green
    Write-Host "`nПодписываюсь на все топики на ${Timeout} секунд...`n" -ForegroundColor Yellow
    
    # Подписываемся на все топики
    $topics = @(
        "homeassistant/sensor/+/state",
        "homeassistant/sensor/pc_socket_power/+",
        "sensor/+/state",
        "zigbee2mqtt/+/power",
        "#"
    )
    
    foreach ($topic in $topics) {
        Write-Host "📡 Подписка на: $topic" -ForegroundColor Cyan
        Start-Process -FilePath "mosquitto_sub" -ArgumentList @(
            "-h", $Broker,
            "-p", $Port,
            "-u", $User,
            "-P", $Password,
            "-t", $topic,
            "-C", "10"
        ) -NoNewWindow -Wait
    }
} else {
    Write-Host "⚠️  mosquitto_sub не найден" -ForegroundColor Yellow
    Write-Host "Установи Mosquitto или используй Python скрипт`n" -ForegroundColor Yellow
}

Write-Host "`n💡 Рекомендации:" -ForegroundColor Cyan
Write-Host "1. Открой Home Assistant → Настройки → Устройства и службы" -ForegroundColor White
Write-Host "2. Найди свою розетку (pc_socket_power)" -ForegroundColor White
Write-Host "3. Открой настройки устройства" -ForegroundColor White
Write-Host "4. Посмотри MQTT топик в настройках сенсора" -ForegroundColor White
Write-Host "`nИли используй MQTT Explorer для визуального просмотра всех топиков" -ForegroundColor Yellow

