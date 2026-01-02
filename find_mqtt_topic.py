#!/usr/bin/env python3
"""
Скрипт для поиска MQTT топика сенсора мощности розетки в Home Assistant
Использование: python find_mqtt_topic.py
"""

import paho.mqtt.client as mqtt
import time
import json

# MQTT настройки (из твоего main.cpp)
MQTT_BROKER = "192.168.88.13"
MQTT_PORT = 30081
MQTT_USER = "mqtt"
MQTT_PASSWORD = "mqtt"

# Список найденных топиков
found_topics = {}

def on_connect(client, userdata, flags, rc):
    """Вызывается при подключении к MQTT брокеру"""
    if rc == 0:
        print("✅ Подключено к MQTT брокеру!")
        print(f"📡 Подписываюсь на топики связанные с 'socket' и 'power'...\n")
        
        # Подписываемся на все возможные топики
        # Home Assistant обычно использует такие паттерны:
        topics_to_subscribe = [
            "homeassistant/sensor/+/state",           # Все сенсоры HA
            "homeassistant/sensor/+/+/state",         # Вложенные сенсоры
            "homeassistant/+/pc_socket_power/+",      # Конкретно твоя розетка
            "homeassistant/sensor/pc_socket_power/+", # Твой сенсор
            "sensor/+/state",                         # Альтернативный формат
            "sensor/pc_socket_power/+",               # Альтернативный формат
            "zigbee2mqtt/+/power",                    # Если используется Zigbee2MQTT
            "zigbee2mqtt/+/+/power",                  # Zigbee2MQTT вложенный
            "+/power",                                # Любой топик с power
            "+/+/power",                              # Вложенный power
            "#",                                      # ВСЕ топики (осторожно!)
        ]
        
        for topic in topics_to_subscribe:
            try:
                client.subscribe(topic, qos=0)
                print(f"  ✓ Подписался на: {topic}")
            except Exception as e:
                print(f"  ✗ Ошибка подписки на {topic}: {e}")
        
        print("\n⏳ Слушаю сообщения 30 секунд...")
        print("   (Измени значение в коде, если нужно больше времени)\n")
    else:
        print(f"❌ Ошибка подключения, код: {rc}")

def on_message(client, userdata, msg):
    """Вызывается при получении сообщения"""
    topic = msg.topic
    payload = msg.payload.decode('utf-8', errors='ignore')
    
    # Сохраняем топик и данные
    if topic not in found_topics:
        found_topics[topic] = []
    
    found_topics[topic].append({
        'payload': payload,
        'timestamp': time.time()
    })
    
    # Проверяем, содержит ли payload числовое значение (мощность)
    try:
        value = float(payload)
        if value > 0 and value < 10000:  # Разумный диапазон для мощности в ваттах
            print(f"🔍 НАЙДЕН ПОТЕНЦИАЛЬНЫЙ ТОПИК!")
            print(f"   Топик: {topic}")
            print(f"   Значение: {value} Вт")
            print(f"   Payload: {payload}\n")
    except ValueError:
        # Пробуем парсить JSON
        try:
            data = json.loads(payload)
            # Ищем числовые значения в JSON
            for key, val in data.items():
                if isinstance(val, (int, float)) and val > 0 and val < 10000:
                    print(f"🔍 НАЙДЕН ПОТЕНЦИАЛЬНЫЙ ТОПИК!")
                    print(f"   Топик: {topic}")
                    print(f"   Поле: {key} = {val} Вт")
                    print(f"   Payload: {payload}\n")
                    break
        except json.JSONDecodeError:
            pass
    
    # Выводим все сообщения для отладки
    print(f"📨 [{topic}] {payload[:100]}")  # Первые 100 символов

def main():
    print("=" * 60)
    print("🔎 Поиск MQTT топика для сенсора мощности розетки")
    print("=" * 60)
    print(f"Брокер: {MQTT_BROKER}:{MQTT_PORT}")
    print(f"Пользователь: {MQTT_USER}\n")
    
    # Создаем MQTT клиент
    client = mqtt.Client(client_id="topic_finder", clean_session=True)
    client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
    client.on_connect = on_connect
    client.on_message = on_message
    
    try:
        # Подключаемся
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        
        # Слушаем 30 секунд
        client.loop_start()
        time.sleep(30)
        client.loop_stop()
        
        # Выводим результаты
        print("\n" + "=" * 60)
        print("📊 РЕЗУЛЬТАТЫ ПОИСКА")
        print("=" * 60)
        
        if found_topics:
            print(f"\nНайдено {len(found_topics)} уникальных топиков:\n")
            for topic, messages in found_topics.items():
                print(f"  📌 {topic}")
                print(f"     Сообщений: {len(messages)}")
                if messages:
                    print(f"     Последнее: {messages[-1]['payload'][:80]}")
                print()
        else:
            print("\n⚠️  Топики не найдены. Возможные причины:")
            print("   - Розетка не отправляет данные в данный момент")
            print("   - Неправильный формат подписки")
            print("   - Проблемы с подключением к MQTT")
            print("\n💡 Попробуй:")
            print("   1. Включи/выключи розетку, чтобы она отправила данные")
            print("   2. Проверь настройки MQTT в Home Assistant")
            print("   3. Используй MQTT Explorer для визуального просмотра")
        
    except Exception as e:
        print(f"\n❌ Ошибка: {e}")
        print("\n💡 Убедись, что:")
        print("   - MQTT брокер доступен")
        print("   - Установлен paho-mqtt: pip install paho-mqtt")
        print("   - Правильные учетные данные")
    finally:
        client.disconnect()

if __name__ == "__main__":
    main()

