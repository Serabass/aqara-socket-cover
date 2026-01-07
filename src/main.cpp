#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Arduino.h>
#include <Wire.h>

#include "AqaraSocketScreen.h"
#include "ha_client.h"
#include "secrets.h" // Секреты и конфигурация (не попадает в git)
#include "wifi_manager.h"

#define HA_ENTITY_NAME "conditioner_socket"
// Entity ID сенсоров (используют HA_ENTITY_NAME из secrets.h)
#define HA_ENTITY_POWER "sensor." HA_ENTITY_NAME "_power"
#define HA_ENTITY_VOLTAGE "sensor." HA_ENTITY_NAME "_voltage"
#define HA_ENTITY_CURRENT "sensor." HA_ENTITY_NAME "_current"
#define HA_ENTITY_ENERGY "sensor." HA_ENTITY_NAME "_energy"

// ===== КОНФИГУРАЦИЯ КОЛИЧЕСТВА ЭКРАНОВ =====
// Установи количество экранов: 1, 2 или 4
// 1 экран - все 4 показателя мелким шрифтом на одном дисплее
// 2 экрана - по 2 показателя на каждый экран (POWER+VOLTAGE, ENERGY+CURRENT)
// 4 экрана - по 1 показателю на каждый экран (требует I2C мультиплексор или
// разные адреса)
#define DISPLAY_COUNT 1

// OLED SSD1306 через I2C
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
// Первый дисплей
#define OLED1_SDA 22
#define OLED1_SCL 23
// Второй дисплей
#define OLED2_SDA 25
#define OLED2_SCL 26
// Третий дисплей (для 4 экранов)
#define OLED3_SDA 27
#define OLED3_SCL 14
// Четвертый дисплей (для 4 экранов)
#define OLED4_SDA 12
#define OLED4_SCL 13
#define OLED_ADDR 0x3C

#define TEXT_SIZE 2.5
#define TEXT_SIZE_SMALL 1.5 // Мелкий шрифт для 1 экрана

// LED индикатор WiFi (можно отключить через макрос)
// Используем встроенный LED на ESP32 DevKit V1 (GPIO2)
#define ENABLE_WIFI_LED // Установи в 0 для отключения LED
#ifdef ENABLE_WIFI_LED
#define WIFI_LED_PIN 2 // Встроенный LED на ESP32 DevKit V1
#endif

// Интервал обновления данных (в миллисекундах)
#define UPDATE_INTERVAL_MS 10000 // 10 секунд

// Объекты дисплеев (условная компиляция)
#if DISPLAY_COUNT >= 1
AqaraSocketScreen display1(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
#endif

#if DISPLAY_COUNT >= 2
AqaraSocketScreen display2(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire1, -1);
#endif

#if DISPLAY_COUNT >= 4
// ВНИМАНИЕ: Для 4 экранов с SSD1306 (адрес 0x3C) нужен I2C мультиплексор
// (например, TCA9548A) или дисплеи с разными адресами. Здесь используем
// заглушки. Для работы нужно:
// 1. Использовать I2C мультиплексор TCA9548A
// 2. Или использовать дисплеи с разными адресами (0x3C, 0x3D)
// 3. Или использовать программный I2C (требует специальной библиотеки)
AqaraSocketScreen display3(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
AqaraSocketScreen display4(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire1, -1);
#endif

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
#ifdef ENABLE_WIFI_LED
void init_wifi_led() {
  pinMode(WIFI_LED_PIN, OUTPUT);
  digitalWrite(WIFI_LED_PIN, LOW);
  Serial.printf("WiFi LED инициализирован на GPIO%d\n", WIFI_LED_PIN);
}
#endif

// Обновление состояния LED в зависимости от подключения WiFi
#ifdef ENABLE_WIFI_LED
void update_wifi_led(bool connected) {
  digitalWrite(WIFI_LED_PIN, connected ? HIGH : LOW);
}
#endif

// Обновление всех дисплеев в зависимости от конфигурации
void update_displays() {
  // Подготовка данных сенсоров
  SensorData power_data = {power, power_valid, prev_power, first_update_power,
                           "W"};
  SensorData voltage_data = {voltage, voltage_valid, prev_voltage,
                             first_update_voltage, "V"};
  SensorData current_data = {current, current_valid, prev_current,
                             first_update_current, "A"};
  SensorData energy_data = {energy, energy_valid, prev_energy,
                            first_update_energy, "kWh"};

#if DISPLAY_COUNT == 1
  // 1 экран - все 4 показателя в 4 строки, выровненные по точке (без меток)
  display1.showAllSensors(power_data, voltage_data, energy_data, current_data);

#elif DISPLAY_COUNT == 2
  // 2 экрана - по 2 показателя на каждый
  // Первый экран: POWER и VOLTAGE
  display1.showTwoSensors(power_data, "POWER", voltage_data, "VOLTAGE", 0, 32,
                          (uint8_t)TEXT_SIZE);
  // Второй экран: ENERGY и CURRENT
  display2.showTwoSensors(energy_data, "ENERGY", current_data, "CURRENT", 0, 32,
                          (uint8_t)TEXT_SIZE);

#elif DISPLAY_COUNT == 4
  // 4 экрана - по 1 показателю на каждый
  // ВНИМАНИЕ: Для работы 4 экранов нужен I2C мультиплексор или разные адреса
  display1.showSingleSensor(power_data, "POWER", 16, (uint8_t)TEXT_SIZE);
  display2.showSingleSensor(voltage_data, "VOLTAGE", 16, (uint8_t)TEXT_SIZE);
  display3.showSingleSensor(energy_data, "ENERGY", 16, (uint8_t)TEXT_SIZE);
  display4.showSingleSensor(current_data, "CURRENT", 16, (uint8_t)TEXT_SIZE);
#endif
}

void setup() {
  // Инициализация Serial для отладки
  Serial.begin(115200);
  delay(100);

  Serial.println("========================================");
  Serial.println("Запуск приложения ESP32 (Arduino)");
  Serial.println("========================================");

  // Инициализация дисплеев в зависимости от конфигурации
#if DISPLAY_COUNT >= 1
  Wire.begin(OLED1_SDA, OLED1_SCL);
  Serial.println("Инициализация первого OLED SSD1306...");
  if (!display1.begin(OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать первый OLED!");
    while (1)
      delay(1000);
  }
  Serial.println("Первый OLED инициализирован успешно!");
  // Показываем анимацию инициализации
  for (int i = 0; i < 8; i++) {
    display1.showInitAnimation();
    delay(150);
  }
#endif

#if DISPLAY_COUNT >= 2
  Wire1.begin(OLED2_SDA, OLED2_SCL);
  Serial.println("Инициализация второго OLED SSD1306...");
  if (!display2.begin(OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать второй OLED!");
    while (1)
      delay(1000);
  }
  Serial.println("Второй OLED инициализирован успешно!");
  // Показываем анимацию инициализации
  for (int i = 0; i < 8; i++) {
    display2.showInitAnimation();
    delay(150);
  }
#endif

#if DISPLAY_COUNT >= 4
  // ВНИМАНИЕ: Для 4 экранов с SSD1306 (адрес 0x3C) нужен I2C мультиплексор
  // (например, TCA9548A) или дисплеи с разными адресами (0x3C и 0x3D). Здесь
  // используем те же шины. Для правильной работы нужно использовать
  // мультиплексор или программный I2C.
  Serial.println(
      "ВНИМАНИЕ: 4 экрана требуют I2C мультиплексор или разные адреса!");
  Serial.println("Инициализация 3-го и 4-го OLED (используют те же шины - "
                 "нужен мультиплексор)...");
  // Пока используем те же шины - для работы нужен мультиплексор
  if (!display3.begin(OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать третий OLED!");
  } else {
    Serial.println(
        "Третий OLED инициализирован (требует мультиплексор для работы)!");
  }
  if (!display4.begin(OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать четвертый OLED!");
  } else {
    Serial.println(
        "Четвертый OLED инициализирован (требует мультиплексор для работы)!");
  }
  // Показываем анимацию инициализации для 3-го и 4-го экранов
  for (int i = 0; i < 8; i++) {
    display3.showInitAnimation();
    display4.showInitAnimation();
    delay(150);
  }
#endif

  // Инициализация WiFi
  Serial.println("Инициализация WiFi...");
  wifi_manager_init(WIFI_SSID, WIFI_PASSWORD);

  // Инициализация LED индикатора WiFi
#ifdef ENABLE_WIFI_LED
  init_wifi_led();
#endif

  // Инициализация Home Assistant клиента
  Serial.println("Инициализация Home Assistant клиента...");
  ha_client_init(HA_SERVER, HA_PORT, HA_TOKEN);

  // Первое обновление дисплеев
  update_displays();

  // Обновляем LED статус
#ifdef ENABLE_WIFI_LED
  update_wifi_led(wifi_manager_is_connected());
#endif

  Serial.println("Приложение запущено");
}

void loop() {
  // Проверяем подключение WiFi
  bool wifi_connected = wifi_manager_is_connected();
  update_wifi_led(wifi_connected);

  if (!wifi_connected) {
    Serial.println("WiFi не подключен, ждем...");
    update_displays();
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
        prev_power = power; // Первое значение = предыдущее
      }
      Serial.printf("Мощность: %.1f Вт\n", power);
    } else {
      power_valid = false;
      Serial.printf("Ошибка получения мощности: %s\n",
                    ha_client_get_last_error());
    }

    delay(500); // Небольшая задержка между запросами

    if (ha_client_fetch_sensor(HA_ENTITY_VOLTAGE, &voltage)) {
      voltage_valid = true;
      if (first_update_voltage) {
        first_update_voltage = false;
        prev_voltage = voltage; // Первое значение = предыдущее
      }
      Serial.printf("Напряжение: %.1f В\n", voltage);
    } else {
      voltage_valid = false;
      Serial.printf("Ошибка получения напряжения: %s\n",
                    ha_client_get_last_error());
    }

    delay(500);

    if (ha_client_fetch_sensor(HA_ENTITY_CURRENT, &current)) {
      current_valid = true;
      if (first_update_current) {
        first_update_current = false;
        prev_current = current; // Первое значение = предыдущее
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
        prev_energy = energy; // Первое значение = предыдущее
      }
      Serial.printf("Энергия: %.1f кВт·ч\n", energy);
    } else {
      energy_valid = false;
      Serial.printf("Ошибка получения энергии: %s\n",
                    ha_client_get_last_error());
    }

    // Обновляем дисплеи (сравнивает текущие значения с предыдущими)
    update_displays();

    // Сохраняем текущие значения как предыдущие для следующего обновления
    if (power_valid)
      prev_power = power;
    if (voltage_valid)
      prev_voltage = voltage;
    if (current_valid)
      prev_current = current;
    if (energy_valid)
      prev_energy = energy;
  }

  delay(1000);
}
