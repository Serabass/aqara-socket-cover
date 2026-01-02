# Как найти MQTT топик для сенсора мощности розетки

## Способ 1: Через Home Assistant (САМЫЙ ПРОСТОЙ)

1. **Открой Home Assistant** в браузере
2. Перейди в **Настройки → Устройства и службы**
3. Найди свою розетку (ищи `pc_socket_power` или название розетки)
4. Кликни на устройство
5. Найди сенсор мощности (обычно называется "Power" или "Мощность")
6. Кликни на сенсор → **Настройки** (шестеренка)
7. В настройках найди **MQTT топик** или **State topic**
8. Скопируй топик

Обычно топики выглядят так:
- `homeassistant/sensor/pc_socket_power/state`
- `sensor/pc_socket_power/state`
- `zigbee2mqtt/0x12345678/power` (если используется Zigbee2MQTT)

## Способ 2: Через Python скрипт (АВТОМАТИЧЕСКИЙ)

1. **Установи библиотеку:**
   ```powershell
   pip install paho-mqtt
   ```

2. **Запусти скрипт:**
   ```powershell
   python find_mqtt_topic.py
   ```

3. Скрипт подключится к MQTT и подпишется на все возможные топики
4. Включи/выключи розетку, чтобы она отправила данные
5. Скрипт покажет все топики с числовыми значениями (мощность)

## Способ 3: Через MQTT Explorer (ВИЗУАЛЬНЫЙ)

1. **Скачай MQTT Explorer:** https://mqtt-explorer.com/
2. **Подключись к брокеру:**
   - Host: `192.168.88.13`
   - Port: `30081`
   - Username: `mqtt`
   - Password: `mqtt`
3. **Просмотри все топики** в дереве слева
4. Найди топики связанные с `socket`, `power`, `pc_socket`
5. Кликни на топик и посмотри данные

## Способ 4: Через mosquitto_sub (КОМАНДНАЯ СТРОКА)

Если у тебя установлен Mosquitto:

```powershell
# Подписка на все топики Home Assistant
mosquitto_sub -h 192.168.88.13 -p 30081 -u mqtt -P mqtt -t "homeassistant/sensor/+/state" -v

# Или конкретно твоя розетка
mosquitto_sub -h 192.168.88.13 -p 30081 -u mqtt -P mqtt -t "homeassistant/sensor/pc_socket_power/+" -v

# Или все топики (осторожно, будет много!)
mosquitto_sub -h 192.168.88.13 -p 30081 -u mqtt -P mqtt -t "#" -v
```

## Способ 5: Через ESP32 (ОТЛАДКА)

Можешь модифицировать свой код, чтобы он подписывался на все топики и выводил их:

```cpp
// В функции reconnect() добавь:
client.subscribe("homeassistant/sensor/+/state");
client.subscribe("homeassistant/sensor/pc_socket_power/+");
client.subscribe("#");  // Все топики

// В callback() просто выводи все топики:
Serial.print("Топик: ");
Serial.println(topic);
Serial.print("Данные: ");
Serial.println(message);
```

## Типичные форматы топиков

### Home Assistant Auto Discovery:
- `homeassistant/sensor/pc_socket_power/state` - состояние
- `homeassistant/sensor/pc_socket_power/config` - конфигурация

### Zigbee2MQTT:
- `zigbee2mqtt/PC Socket/power` - мощность
- `zigbee2mqtt/PC Socket` - все данные устройства (JSON)

### Прямой MQTT:
- `sensor/pc_socket_power/state`
- `devices/pc_socket/power`

## После нахождения топика

Обнови в `src/main.cpp`:
```cpp
const char *sensor_topic = "НАЙДЕННЫЙ_ТОПИК";
```

И перезагрузи код на ESP32!

