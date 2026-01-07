#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Arduino.h>
#include <Wire.h>

#include "ha_client.h"
#include "wifi_manager.h"

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
#define HA_SERVER "192.168.88.13" // IP адрес Home Assistant
#define HA_PORT 30123             // Порт Home Assistant
#define HA_TOKEN                                                               \
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."                                      \
  "eyJpc3MiOiJkZWU1MDMxNTUwOGM0OGVkOGYzOTVjNTJkOTM1YzllMCIsImlhdCI6MTc2NzI3Mj" \
  "UxMywiZXhwIjoyMDgyNjMyNTEzfQ.hSO2cB2AGafJQgpSCoRIS9B2tlsBHoO-Iv83sjfplDs" // Long-Lived Access Token

// Entity ID сенсоров
#define HA_ENTITY_NAME "conditioner_socket"
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
Adafruit_SSD1306 display1(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
#endif

#if DISPLAY_COUNT >= 2
Adafruit_SSD1306 display2(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire1, -1);
#endif

#if DISPLAY_COUNT >= 4
// ВНИМАНИЕ: Для 4 экранов с SSD1306 (адрес 0x3C) нужен I2C мультиплексор
// (например, TCA9548A) или дисплеи с разными адресами. Здесь используем
// заглушки. Для работы нужно:
// 1. Использовать I2C мультиплексор TCA9548A
// 2. Или использовать дисплеи с разными адресами (0x3C, 0x3D)
// 3. Или использовать программный I2C (требует специальной библиотеки)
Adafruit_SSD1306 display3(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
Adafruit_SSD1306 display4(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire1, -1);
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

// Анимация инициализации (вращающийся индикатор)
void show_init_animation(Adafruit_SSD1306 &disp) {
  const char *spinner_chars = "|/-\\"; // Символы для анимации
  static int spinner_index = 0;

  disp.clearDisplay();
  disp.setTextSize(2);
  disp.setTextColor(SSD1306_WHITE);

  // Центрируем анимацию
  disp.setCursor(50, 20);
  disp.print(spinner_chars[spinner_index]);

  spinner_index = (spinner_index + 1) % 4; // Цикл через 4 символа
  disp.display();
}

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

// Функция форматирования числа с заменой ведущих нулей на пробелы
// Поддерживает числа до 9999.99
void format_number(char *buffer, size_t size, float value) {
  // Форматируем с ведущими нулями (7 символов: 4 цифры + точка + 2 цифры)
  snprintf(buffer, size, "%07.2f", value);

  // Заменяем ведущие нули на пробелы (но оставляем один ноль перед точкой)
  for (size_t i = 0; i < strlen(buffer) - 1; i++) {
    if (buffer[i] == '0' && buffer[i + 1] != '.') {
      buffer[i] = ' ';
    } else {
      break; // Останавливаемся на первой не-нулевой цифре или точке
    }
  }
}

// Кастомные символы стрелок (8x8 пикселей)
// Стрелка вверх
static const unsigned char arrow_up_bmp[] = {0B00011000, 0B00111100, 0B01111110,
                                             0B11111111, 0B00011000, 0B00011000,
                                             0B00011000, 0B00000000};

// Стрелка вниз
static const unsigned char arrow_down_bmp[] = {
    0B00011000, 0B00011000, 0B00011000, 0B11111111,
    0B01111110, 0B00111100, 0B00011000, 0B00000000};

// Функция для отображения стрелки на дисплее
void draw_arrow(Adafruit_SSD1306 &disp, int x, int y, bool is_up) {
  disp.drawBitmap(x, y, is_up ? arrow_up_bmp : arrow_down_bmp, 8, 8,
                  SSD1306_WHITE);
}

// Функция для получения типа изменения значения
// Возвращает: 1 = вверх, -1 = вниз, 0 = без изменений
int get_change_direction(float current, float previous, bool is_first) {
  if (is_first) {
    return 0; // Первое обновление - без стрелки
  }

  const float threshold =
      0.01f; // Порог для учета изменений (избегаем дрожания)

  if (current > previous + threshold) {
    return 1; // Стрелка вверх
  } else if (current < previous - threshold) {
    return -1; // Стрелка вниз
  } else {
    return 0; // Без изменений
  }
}

// Функция отображения одного показателя на дисплее (без метки)
void show_sensor_value(Adafruit_SSD1306 &disp, const char *label, float value,
                       bool valid, float prev_value, bool is_first,
                       const char *unit, int y_pos, uint8_t text_size,
                       int label_x_pos = 0) {
  char buffer[32];
  char full_text[32];

  // Метки убраны - назначение понятно по единице измерения

  // Формируем полный текст значения
  if (valid) {
    format_number(buffer, sizeof(buffer), value);
    snprintf(full_text, sizeof(full_text), "%s %s", buffer, unit);
  } else {
    strncpy(full_text, "    .00", sizeof(full_text));
  }

  // Значение - центрируем по горизонтали
  disp.setTextSize(text_size);
  int text_width =
      strlen(full_text) * 6 * text_size; // Примерная ширина символа 6 пикселей
  int x_pos = (128 - text_width) / 2;    // Центрируем на экране шириной 128
  if (x_pos < 0)
    x_pos = 0; // Не выходим за границы
  disp.setCursor(x_pos, y_pos);
  disp.print(full_text);

  // Показываем стрелку изменения справа от текста
  int change_dir = get_change_direction(value, prev_value, is_first);
  if (change_dir != 0) {
    int arrow_x =
        x_pos + text_width + 2; // Справа от текста с небольшим отступом
    if (arrow_x + 8 <= 128) {   // Проверяем, что стрелка поместится
      draw_arrow(disp, arrow_x, y_pos, change_dir == 1);
    }
  }
}

// Функция для выравнивания числа по точке (для 1 экрана)
// label_len - длина метки (например, "POWER: " = 7)
// dot_char_position - позиция точки в символах от начала строки (после метки)
// Возвращает строку с пробелами перед числом, чтобы точка была на фиксированной
// позиции
void format_number_aligned(char *output, size_t output_size, float value,
                           int label_len, int dot_char_position) {
  char buffer[16];
  format_number(buffer, sizeof(buffer), value);

  // Находим позицию точки в отформатированном числе
  char *dot_ptr = strchr(buffer, '.');
  if (dot_ptr == NULL) {
    // Если точки нет, просто копируем
    strncpy(output, buffer, output_size);
    return;
  }

  // Позиция точки в отформатированном числе (от начала числа)
  int dot_pos_in_number = dot_ptr - buffer;

  // Позиция точки должна быть на dot_char_position от начала строки
  // label_len + spaces + dot_pos_in_number = dot_char_position
  // spaces = dot_char_position - label_len - dot_pos_in_number
  int spaces_needed = dot_char_position - label_len - dot_pos_in_number;
  if (spaces_needed < 0)
    spaces_needed = 0;

  // Заполняем пробелами
  int i = 0;
  for (; i < spaces_needed && i < output_size - 1; i++) {
    output[i] = ' ';
  }
  // Копируем число
  strncpy(output + i, buffer, output_size - i);
  output[output_size - 1] = '\0';
}

// Обновление всех дисплеев в зависимости от конфигурации
void update_displays() {
#if DISPLAY_COUNT == 1
  // 1 экран - все 4 показателя в 4 строки, выровненные по точке (без меток)
  display1.clearDisplay();
  display1.setTextSize(1);
  display1.setTextColor(SSD1306_WHITE);

  char aligned_buffer[32];
  int line_height = 16;      // Высота строки (64 / 4 = 16)
  int dot_char_position = 8; // Позиция точки в символах от начала строки

  // POWER - только значение с единицей
  display1.setCursor(0, 0);
  if (power_valid) {
    format_number_aligned(aligned_buffer, sizeof(aligned_buffer), power, 0,
                          dot_char_position);
    display1.print(aligned_buffer);
    display1.print(" W");
    int change_dir =
        get_change_direction(power, prev_power, first_update_power);
    if (change_dir != 0) {
      draw_arrow(display1, 100, 0, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4; // 4 символа для " .00"
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      display1.print(" ");
    display1.print("    .00 W");
  }

  // VOLTAGE - только значение с единицей
  display1.setCursor(0, line_height);
  if (voltage_valid) {
    format_number_aligned(aligned_buffer, sizeof(aligned_buffer), voltage, 0,
                          dot_char_position);
    display1.print(aligned_buffer);
    display1.print(" V");
    int change_dir =
        get_change_direction(voltage, prev_voltage, first_update_voltage);
    if (change_dir != 0) {
      draw_arrow(display1, 100, line_height, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4;
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      display1.print(" ");
    display1.print("    .00 V");
  }

  // ENERGY - только значение с единицей
  display1.setCursor(0, line_height * 2);
  if (energy_valid) {
    format_number_aligned(aligned_buffer, sizeof(aligned_buffer), energy, 0,
                          dot_char_position);
    display1.print(aligned_buffer);
    display1.print(" kWh");
    int change_dir =
        get_change_direction(energy, prev_energy, first_update_energy);
    if (change_dir != 0) {
      draw_arrow(display1, 100, line_height * 2, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4;
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      display1.print(" ");
    display1.print("    .00 kWh");
  }

  // CURRENT - только значение с единицей
  display1.setCursor(0, line_height * 3);
  if (current_valid) {
    format_number_aligned(aligned_buffer, sizeof(aligned_buffer), current, 0,
                          dot_char_position);
    display1.print(aligned_buffer);
    display1.print(" A");
    int change_dir =
        get_change_direction(current, prev_current, first_update_current);
    if (change_dir != 0) {
      draw_arrow(display1, 100, line_height * 3, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4;
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      display1.print(" ");
    display1.print("    .00 A");
  }

  display1.display();

#elif DISPLAY_COUNT == 2
  // 2 экрана - по 2 показателя на каждый
  // Первый экран: POWER и VOLTAGE
  display1.clearDisplay();
  display1.setTextSize(TEXT_SIZE);
  display1.setTextColor(SSD1306_WHITE);
  // POWER - верхняя часть, метка внизу слева
  show_sensor_value(display1, "POWER", power, power_valid, prev_power,
                    first_update_power, "W", 0, (uint8_t)TEXT_SIZE, 0);
  // VOLTAGE - нижняя часть, метка внизу справа
  show_sensor_value(display1, "VOLTAGE", voltage, voltage_valid, prev_voltage,
                    first_update_voltage, "V", 32, (uint8_t)TEXT_SIZE, 70);
  display1.display();

  // Второй экран: ENERGY и CURRENT
  display2.clearDisplay();
  display2.setTextSize(TEXT_SIZE);
  display2.setTextColor(SSD1306_WHITE);
  // ENERGY - верхняя часть, метка внизу слева
  show_sensor_value(display2, "ENERGY", energy, energy_valid, prev_energy,
                    first_update_energy, "kWh", 0, (uint8_t)TEXT_SIZE, 0);
  // CURRENT - нижняя часть, метка внизу справа
  show_sensor_value(display2, "CURRENT", current, current_valid, prev_current,
                    first_update_current, "A", 32, (uint8_t)TEXT_SIZE, 70);
  display2.display();

#elif DISPLAY_COUNT == 4
  // 4 экрана - по 1 показателю на каждый
  // ВНИМАНИЕ: Для работы 4 экранов нужен I2C мультиплексор или разные адреса
  // Экран 1: POWER
  display1.clearDisplay();
  display1.setTextSize(TEXT_SIZE);
  display1.setTextColor(SSD1306_WHITE);
  show_sensor_value(display1, "POWER", power, power_valid, prev_power,
                    first_update_power, "W", 16, (uint8_t)TEXT_SIZE, 0);
  display1.display();

  // Экран 2: VOLTAGE
  display2.clearDisplay();
  display2.setTextSize(TEXT_SIZE);
  display2.setTextColor(SSD1306_WHITE);
  show_sensor_value(display2, "VOLTAGE", voltage, voltage_valid, prev_voltage,
                    first_update_voltage, "V", 16, (uint8_t)TEXT_SIZE, 0);
  display2.display();

  // Экран 3: ENERGY (требует мультиплексор или другой адрес)
  display3.clearDisplay();
  display3.setTextSize(TEXT_SIZE);
  display3.setTextColor(SSD1306_WHITE);
  show_sensor_value(display3, "ENERGY", energy, energy_valid, prev_energy,
                    first_update_energy, "kWh", 16, (uint8_t)TEXT_SIZE, 0);
  display3.display();

  // Экран 4: CURRENT (требует мультиплексор или другой адрес)
  display4.clearDisplay();
  display4.setTextSize(TEXT_SIZE);
  display4.setTextColor(SSD1306_WHITE);
  show_sensor_value(display4, "CURRENT", current, current_valid, prev_current,
                    first_update_current, "A", 16, (uint8_t)TEXT_SIZE, 0);
  display4.display();
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
  if (!display1.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать первый OLED!");
    while (1)
      delay(1000);
  }
  Serial.println("Первый OLED инициализирован успешно!");
  // Показываем анимацию инициализации
  for (int i = 0; i < 8; i++) {
    show_init_animation(display1);
    delay(150);
  }
#endif

#if DISPLAY_COUNT >= 2
  Wire1.begin(OLED2_SDA, OLED2_SCL);
  Serial.println("Инициализация второго OLED SSD1306...");
  if (!display2.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать второй OLED!");
    while (1)
      delay(1000);
  }
  Serial.println("Второй OLED инициализирован успешно!");
  // Показываем анимацию инициализации
  for (int i = 0; i < 8; i++) {
    show_init_animation(display2);
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
  if (!display3.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать третий OLED!");
  } else {
    Serial.println(
        "Третий OLED инициализирован (требует мультиплексор для работы)!");
  }
  if (!display4.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("ОШИБКА: Не удалось инициализировать четвертый OLED!");
  } else {
    Serial.println(
        "Четвертый OLED инициализирован (требует мультиплексор для работы)!");
  }
  // Показываем анимацию инициализации для 3-го и 4-го экранов
  for (int i = 0; i < 8; i++) {
    show_init_animation(display3);
    show_init_animation(display4);
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
