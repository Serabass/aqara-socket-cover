#include <Wire.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#include <Arduino.h>
#include "wifi_manager.h"
#include "ha_client.h"

// ===== НАСТРОЙКИ =====
// WiFi
// Для Wokwi используй "Wokwi-GUEST" без пароля
// Для реального ESP32 измени на свои данные
#if defined(WOKWI)
    #define WIFI_SSID "Wokwi-GUEST"
    #define WIFI_PASSWORD ""
#else
    #define WIFI_SSID "MikroTik-9DA0AC"
    #define WIFI_PASSWORD "MYZLMGFPT3"
#endif

// Home Assistant
#define HA_SERVER "192.168.88.13"  // IP адрес Home Assistant
#define HA_PORT 30123                // Порт Home Assistant
#define HA_TOKEN "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkZWU1MDMxNTUwOGM0OGVkOGYzOTVjNTJkOTM1YzllMCIsImlhdCI6MTc2NzI3MjUxMywiZXhwIjoyMDgyNjMyNTEzfQ.hSO2cB2AGafJQgpSCoRIS9B2tlsBHoO-Iv83sjfplDs"  // Long-Lived Access Token

// Entity ID сенсоров
#define HA_ENTITY_POWER "sensor.servers_socket_power"
#define HA_ENTITY_VOLTAGE "sensor.servers_socket_voltage"
#define HA_ENTITY_CURRENT "sensor.servers_socket_current"
#define HA_ENTITY_ENERGY "sensor.servers_socket_energy"

// OLED SSD1306 через I2C
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_SDA 21
#define OLED_SCL 22
#define OLED_ADDR 0x3C

// LED индикатор WiFi (можно отключить через макрос)
// Используем встроенный LED на ESP32 DevKit V1 (GPIO2)
#define ENABLE_WIFI_LED 1  // Установи в 0 для отключения LED
#define WIFI_LED_PIN 2     // Встроенный LED на ESP32 DevKit V1

// Интервал обновления данных (в миллисекундах)
#define UPDATE_INTERVAL_MS 60000  // 1 минута

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Данные сенсоров
float power = 0.0f;
float voltage = 0.0f;
float current = 0.0f;
float energy = 0.0f;

// Предыдущие значения для сравнения
float prev_power = 0.0f;
float prev_voltage = 0.0f;
float prev_current = 0.0f;
float prev_energy = 0.0f;

bool power_valid = false;
bool voltage_valid = false;
bool current_valid = false;
bool energy_valid = false;

// Флаги для отслеживания первого обновления
bool first_update_power = true;
bool first_update_voltage = true;
bool first_update_current = true;
bool first_update_energy = true;

unsigned long lastUpdate = 0;

// Инициализация LED индикатора WiFi
void init_wifi_led() {
#if ENABLE_WIFI_LED
    pinMode(WIFI_LED_PIN, OUTPUT);
    digitalWrite(WIFI_LED_PIN, LOW);
    Serial.printf("WiFi LED инициализирован на GPIO%d\n", WIFI_LED_PIN);
#endif
}

// Обновление состояния LED в зависимости от подключения WiFi
void update_wifi_led(bool connected) {
#if ENABLE_WIFI_LED
    digitalWrite(WIFI_LED_PIN, connected ? HIGH : LOW);
#endif
}

// Функция форматирования числа с заменой ведущих нулей на пробелы
// Поддерживает числа до 9999.99
void format_number(char* buffer, size_t size, float value) {
    // Форматируем с ведущими нулями (7 символов: 4 цифры + точка + 2 цифры)
    snprintf(buffer, size, "%07.2f", value);
    
    // Заменяем ведущие нули на пробелы (но оставляем один ноль перед точкой)
    for (size_t i = 0; i < strlen(buffer) - 1; i++) {
        if (buffer[i] == '0' && buffer[i+1] != '.') {
            buffer[i] = ' ';
        } else {
            break; // Останавливаемся на первой не-нулевой цифре или точке
        }
    }
}

// Функция для получения символа изменения значения
char get_change_symbol(float current, float previous, bool is_first) {
    if (is_first) {
        return ' ';  // Первое обновление - без стрелки
    }
    
    const float threshold = 0.01f;  // Порог для учета изменений (избегаем дрожания)
    
    if (current > previous + threshold) {
        return '^';  // Стрелка вверх
    } else if (current < previous - threshold) {
        return 'v';  // Стрелка вниз
    } else {
        return ' ';  // Без изменений
    }
}

void update_display() {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    
    char buffer[16];
    
    // Первая строка - мощность (слева, правая область свободна)
    display.setCursor(0, 0);
    display.print("P:");
    if (power_valid) {
        format_number(buffer, sizeof(buffer), power);
        display.print(buffer);
        display.print(" W");
        // Показываем стрелку изменения
        char arrow = get_change_symbol(power, prev_power, first_update_power);
        if (arrow != ' ') {
            display.print(" ");
            display.print(arrow);
        }
    } else {
        display.print("    .00");
    }
    
    // Вторая строка - напряжение (слева, правая область свободна)
    display.setCursor(0, 16);
    display.print("V:");
    if (voltage_valid) {
        format_number(buffer, sizeof(buffer), voltage);
        display.print(buffer);
        display.print(" V");
        // Показываем стрелку изменения
        char arrow = get_change_symbol(voltage, prev_voltage, first_update_voltage);
        if (arrow != ' ') {
            display.print(" ");
            display.print(arrow);
        }
    } else {
        display.print("    .00");
    }
    
    // Третья строка - энергия (слева, правая область свободна)
    display.setCursor(0, 32);
    display.print("E:");
    if (energy_valid) {
        format_number(buffer, sizeof(buffer), energy);
        display.print(buffer);
        display.print(" kWh");
        // Показываем стрелку изменения
        char arrow = get_change_symbol(energy, prev_energy, first_update_energy);
        if (arrow != ' ') {
            display.print(" ");
            display.print(arrow);
        }
    } else {
        display.print("    .00");
    }
    
    // Четвертая строка - ток (слева, правая область свободна)
    display.setCursor(0, 48);
    display.print("I:");
    if (current_valid) {
        format_number(buffer, sizeof(buffer), current);
        display.print(buffer);
        display.print(" A");
        // Показываем стрелку изменения
        char arrow = get_change_symbol(current, prev_current, first_update_current);
        if (arrow != ' ') {
            display.print(" ");
            display.print(arrow);
        }
    } else {
        display.print("    .00");
    }
    
    display.display();
}

void setup() {
    // Инициализация Serial для отладки
    Serial.begin(115200);
    delay(100);
    
    Serial.println("========================================");
    Serial.println("Запуск приложения ESP32 (Arduino)");
    Serial.println("========================================");
    
    // Инициализация I2C
    Wire.begin(OLED_SDA, OLED_SCL);
    
    // Инициализация OLED
    Serial.println("Инициализация OLED SSD1306...");
    if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
        Serial.println("ОШИБКА: Не удалось инициализировать OLED!");
        while (1) delay(1000);
    }
    
    Serial.println("OLED инициализирован успешно!");
    
    // Начальное отображение
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("Initializing...");
    display.display();
    
    // Инициализация WiFi
    Serial.println("Инициализация WiFi...");
    wifi_manager_init(WIFI_SSID, WIFI_PASSWORD);
    
    // Инициализация LED индикатора WiFi
    init_wifi_led();
    
    // Инициализация Home Assistant клиента
    Serial.println("Инициализация Home Assistant клиента...");
    ha_client_init(HA_SERVER, HA_PORT, HA_TOKEN);
    
    // Первое обновление дисплея
    update_display();
    
    // Обновляем LED статус
    update_wifi_led(wifi_manager_is_connected());
    
    Serial.println("Приложение запущено");
}

void loop() {
    // Проверяем подключение WiFi
    bool wifi_connected = wifi_manager_is_connected();
    update_wifi_led(wifi_connected);
    
    if (!wifi_connected) {
        Serial.println("WiFi не подключен, ждем...");
        update_display();
        delay(5000);
        return;
    }
    
    // Обновляем данные каждую минуту
    unsigned long now = millis();
    if (now - lastUpdate >= UPDATE_INTERVAL_MS || lastUpdate == 0) {
        lastUpdate = now;
        
        Serial.println("Запрашиваю данные из Home Assistant...");
        
        // Запрашиваем все сенсоры
        if (ha_client_fetch_sensor(HA_ENTITY_POWER, &power)) {
            power_valid = true;
            if (first_update_power) {
                first_update_power = false;
                prev_power = power;  // Первое значение = предыдущее
            }
            Serial.printf("Мощность: %.1f Вт\n", power);
        } else {
            power_valid = false;
            Serial.printf("Ошибка получения мощности: %s\n", ha_client_get_last_error());
        }
        
        delay(500); // Небольшая задержка между запросами
        
        if (ha_client_fetch_sensor(HA_ENTITY_VOLTAGE, &voltage)) {
            voltage_valid = true;
            if (first_update_voltage) {
                first_update_voltage = false;
                prev_voltage = voltage;  // Первое значение = предыдущее
            }
            Serial.printf("Напряжение: %.1f В\n", voltage);
        } else {
            voltage_valid = false;
            Serial.printf("Ошибка получения напряжения: %s\n", ha_client_get_last_error());
        }
        
        delay(500);
        
        if (ha_client_fetch_sensor(HA_ENTITY_CURRENT, &current)) {
            current_valid = true;
            if (first_update_current) {
                first_update_current = false;
                prev_current = current;  // Первое значение = предыдущее
            }
            Serial.printf("Ток: %.2f А\n", current);
        } else {
            current_valid = false;
            Serial.printf("Ошибка получения тока: %s\n", ha_client_get_last_error());
        }
        
        delay(500);
        
        if (ha_client_fetch_sensor(HA_ENTITY_ENERGY, &energy)) {
            energy_valid = true;
            if (first_update_energy) {
                first_update_energy = false;
                prev_energy = energy;  // Первое значение = предыдущее
            }
            Serial.printf("Энергия: %.1f кВт·ч\n", energy);
        } else {
            energy_valid = false;
            Serial.printf("Ошибка получения энергии: %s\n", ha_client_get_last_error());
        }
        
        // Обновляем дисплей (сравнивает текущие значения с предыдущими)
        update_display();
        
        // Сохраняем текущие значения как предыдущие для следующего обновления
        if (power_valid) prev_power = power;
        if (voltage_valid) prev_voltage = voltage;
        if (current_valid) prev_current = current;
        if (energy_valid) prev_energy = energy;
    }
    
    delay(1000);
}
