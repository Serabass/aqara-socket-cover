/*
 * ============================================================================
 * ИНСТРУКЦИЯ ПО ПОДКЛЮЧЕНИЮ ROBOTDYN 6-DIGIT 7-SEGMENT MODULE (74HC595)
 * ============================================================================
 *
 * У тебя один дисплей на 6 цифр с контроллером 74HC595 (сдвиговый регистр).
 * Дисплей имеет входы: DIO, SCK, RCK, GND, +5V
 *
 * ПОДКЛЮЧЕНИЕ:
 *   DIO  -> GPIO 23 (ESP32)  - Линия данных (Data Input/Output)
 *   SCK  -> GPIO 22 (ESP32)  - Тактовый сигнал (Serial Clock)
 *   RCK  -> GPIO 21 (ESP32)  - Защелка регистра (Register Clock/Latch)
 *   GND  -> GND (ESP32)      - Общий провод (земля)
 *   +5V  -> 5V (ESP32)       - Питание (5V)
 *
 * ВАЖНО:
 * - Дисплей работает через сдвиговые регистры 74HC595
 * - Если цифры отображаются неправильно, попробуй:
 *   1. Инвертировать паттерны (раскомментируй INVERT_PATTERNS)
 *   2. Поменять порядок отправки байтов (LSB/MSB first)
 *   3. Поменять порядок разрядов (массив digitMapping)
 *   4. Проверить соответствие битов сегментам
 *
 * ============================================================================
 */

#include "display_7seg.h"
#include "esp_log.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_rom_sys.h"

static const char *TAG = "DISPLAY_7SEG";

// GPIO пины для 74HC595
#define DISPLAY_DIO GPIO_NUM_23  // Data Input (DS/SER на 74HC595)
#define DISPLAY_SCK GPIO_NUM_22  // Serial Clock (SH_CP/CLK на 74HC595)
#define DISPLAY_RCK GPIO_NUM_21  // Register Clock/Latch (ST_CP/LATCH на 74HC595)

// Опции для отладки (раскомментируй если нужно)
#define INVERT_PATTERNS      // Инвертировать паттерны (для общего анода)
#define REVERSE_BYTE_ORDER   // Отправлять байты в обратном порядке (MSB first)
#define REVERSE_DIGIT_ORDER  // Отправлять цифры в обратном порядке (справа налево)

// Кодировка цифр для 7-сегментного дисплея
// Сегменты: A B C D E F G DP
// Бит:      0 1 2 3 4 5 6 7
// Альтернативная кодировка (если стандартная не работает)
// Попробуем другую схему подключения сегментов
const uint8_t digitPatterns[10] = {
    0b11111100, // 0: A B C D E F (0xFC) - альтернатива
    0b01100000, // 1: B C (0x60)
    0b11011010, // 2: A B D E G (0xDA)
    0b11110010, // 3: A B C D G (0xF2)
    0b01100110, // 4: B C F G (0x66)
    0b10110110, // 5: A C D F G (0xB6)
    0b10111110, // 6: A C D E F G (0xBE)
    0b11100000, // 7: A B C (0xE0)
    0b11111110, // 8: A B C D E F G (0xFE)
    0b11110110  // 9: A B C D F G (0xF6)
};
// Маппинг позиций дисплея (если порядок разрядов нестандартный)
// По умолчанию: 0,1,2,3,4,5 (слева направо)
// Стандартный порядок
static const uint8_t digitMapping[6] = {0, 1, 2, 3, 4, 5};

// Инициализация GPIO пина
static void init_gpio_pin(gpio_num_t pin)
{
  gpio_reset_pin(pin);
  gpio_set_direction(pin, GPIO_MODE_OUTPUT);
  gpio_set_level(pin, 0);
}

// Задержка (микросекунды)
static void delay_us(uint32_t us)
{
  esp_rom_delay_us(us);
}

// Маппинг битов сегментов (логический бит -> физический бит)
// Исправляем перепутанные сегменты на основе наблюдений:
// Наблюдения:
// A → A (правильно)
// B → G (нужно: B → B, значит логический B должен идти на физический G (бит 6), а потом поменять с G)
// C → C (правильно)
// D → E (нужно: D → D, значит логический D должен идти на физический E (бит 4), а потом поменять с E)
// E → D (нужно: E → E, значит логический E должен идти на физический D (бит 3), а потом поменять с D)
// F → F (правильно)
// G → B (нужно: G → G, значит логический G должен идти на физический B (бит 1), а потом поменять с B)
// DP → DP (правильно)
//
// Итого перестановки:
// B (1) ↔ G (6)
// D (3) ↔ E (4)
static uint8_t remap_segment_bits(uint8_t data)
{
  uint8_t result = 0;
  
  // Маппинг: логический бит -> физический бит
  // Логический SEG_A (бит 0) -> Физический бит 0 (SEG_A) - правильно
  if (data & (1 << 0)) result |= (1 << 0);
  // Логический SEG_B (бит 1) -> Физический бит 1 (SEG_B) - исправлено: B должен зажигать B
  if (data & (1 << 1)) result |= (1 << 1);
  // Логический SEG_C (бит 2) -> Физический бит 2 (SEG_C) - правильно
  if (data & (1 << 2)) result |= (1 << 2);
  // Логический SEG_D (бит 3) -> Физический бит 3 (SEG_D) - исправлено: D должен зажигать D
  if (data & (1 << 3)) result |= (1 << 3);
  // Логический SEG_E (бит 4) -> Физический бит 4 (SEG_E) - исправлено: E должен зажигать E
  if (data & (1 << 4)) result |= (1 << 4);
  // Логический SEG_F (бит 5) -> Физический бит 5 (SEG_F) - правильно
  if (data & (1 << 5)) result |= (1 << 5);
  // Логический SEG_G (бит 6) -> Физический бит 6 (SEG_G) - исправлено: G должен зажигать G
  if (data & (1 << 6)) result |= (1 << 6);
  // Логический SEG_DP (бит 7) -> Физический бит 7 (SEG_DP) - правильно
  if (data & (1 << 7)) result |= (1 << 7);
  
  return result;
}

// Отправка одного байта в сдвиговый регистр
// LSB first (младший бит первым) - стандарт для 74HC595
static void shift_out_byte(uint8_t data, gpio_num_t dio_pin, gpio_num_t sck_pin)
{
  // Применяем маппинг битов перед отправкой
  data = remap_segment_bits(data);
  
#ifdef REVERSE_BYTE_ORDER
  // MSB first (старший бит первым)
  for (int i = 7; i >= 0; i--)
  {
    gpio_set_level(dio_pin, (data >> i) & 0x01);
    gpio_set_level(sck_pin, 1);
    delay_us(5);
    gpio_set_level(sck_pin, 0);
    delay_us(5);
  }
#else
  // LSB first (младший бит первым) - стандарт
  for (int i = 0; i < 8; i++)
  {
    gpio_set_level(dio_pin, (data >> i) & 0x01);
    gpio_set_level(sck_pin, 1);
    delay_us(5);
    gpio_set_level(sck_pin, 0);
    delay_us(5);
  }
#endif
}

// Обновление дисплея (6 цифр)
static void update_display(uint8_t digits[6])
{
  // Защелка должна быть LOW во время отправки данных
  gpio_set_level(DISPLAY_RCK, 0);
  delay_us(10);

#ifdef REVERSE_DIGIT_ORDER
  // Отправляем цифры в обратном порядке (справа налево)
  for (int i = 5; i >= 0; i--)
  {
    uint8_t mapped_pos = digitMapping[i];
    uint8_t pattern = digits[mapped_pos];
#ifdef INVERT_PATTERNS
    pattern = ~pattern; // Инвертируем для общего анода
#endif
    shift_out_byte(pattern, DISPLAY_DIO, DISPLAY_SCK);
  }
#else
  // Отправляем цифры слева направо (стандарт)
  for (int i = 0; i < 6; i++)
  {
    uint8_t mapped_pos = digitMapping[i];
    uint8_t pattern = digits[mapped_pos];
#ifdef INVERT_PATTERNS
    pattern = ~pattern; // Инвертируем для общего анода
#endif
    shift_out_byte(pattern, DISPLAY_DIO, DISPLAY_SCK);
  }
#endif

  // Включаем защелку ПОСЛЕ отправки всех данных
  // Это переносит данные из сдвигового регистра в выходной регистр
  gpio_set_level(DISPLAY_RCK, 1);
  delay_us(50);
  gpio_set_level(DISPLAY_RCK, 0);
  delay_us(10);
}

// Разбить число на 6 цифр (0-999999)
static void split_to_6_digits(uint32_t number, uint8_t digits[6])
{
  if (number > 999999)
    number = 999999;
  
  // Заполняем массив справа налево (digits[5] = последняя цифра)
  for (int i = 5; i >= 0; i--)
  {
    digits[i] = digitPatterns[number % 10];
    number /= 10;
  }
}

// Разбить число на 3 цифры (0-999)
static void split_to_3_digits(uint32_t number, uint8_t digits[3])
{
  if (number > 999)
    number = 999;
  
  uint8_t hundreds = number / 100;
  uint8_t tens = (number / 10) % 10;
  uint8_t ones = number % 10;
  
  digits[0] = digitPatterns[hundreds];
  digits[1] = digitPatterns[tens];
  digits[2] = digitPatterns[ones];
}

// Инициализация дисплея
void display_7seg_init(void)
{
  ESP_LOGI(TAG, "Инициализация RobotDyn 6-digit 7-segment (74HC595)");
  
  // Инициализация GPIO
  init_gpio_pin(DISPLAY_DIO);
  init_gpio_pin(DISPLAY_SCK);
  init_gpio_pin(DISPLAY_RCK);
  
  // Очистка дисплея
  display_7seg_clear();
  
  ESP_LOGI(TAG, "Дисплей инициализирован: DIO=%d, SCK=%d, RCK=%d", 
           DISPLAY_DIO, DISPLAY_SCK, DISPLAY_RCK);
#ifdef INVERT_PATTERNS
  ESP_LOGI(TAG, "ВНИМАНИЕ: Паттерны инвертированы (для общего анода)");
#endif
#ifdef REVERSE_BYTE_ORDER
  ESP_LOGI(TAG, "ВНИМАНИЕ: Байты отправляются MSB first");
#endif
#ifdef REVERSE_DIGIT_ORDER
  ESP_LOGI(TAG, "ВНИМАНИЕ: Цифры отправляются в обратном порядке");
#endif
}

void display_7seg_show_left(uint32_t number)
{
  uint8_t digits[6] = {0, 0, 0, 0, 0, 0};
  uint8_t left_digits[3];
  split_to_3_digits(number, left_digits);
  
  // Заполняем левые 3 позиции
  digits[0] = left_digits[0];
  digits[1] = left_digits[1];
  digits[2] = left_digits[2];
  
  update_display(digits);
}

void display_7seg_show_left_direct(uint8_t digits[3])
{
  uint8_t all_digits[6] = {0, 0, 0, 0, 0, 0};
  all_digits[0] = digits[0];
  all_digits[1] = digits[1];
  all_digits[2] = digits[2];
  update_display(all_digits);
}

void display_7seg_show_right_direct(uint8_t digits[3])
{
  uint8_t all_digits[6] = {0, 0, 0, 0, 0, 0};
  all_digits[3] = digits[0];
  all_digits[4] = digits[1];
  all_digits[5] = digits[2];
  update_display(all_digits);
}

void display_7seg_show_direct(uint8_t digits[6])
{
  update_display(digits);
}

void display_7seg_show_right(uint32_t number)
{
  uint8_t digits[6] = {0, 0, 0, 0, 0, 0};
  uint8_t right_digits[3];
  split_to_3_digits(number, right_digits);
  
  // Заполняем правые 3 позиции
  digits[3] = right_digits[0];
  digits[4] = right_digits[1];
  digits[5] = right_digits[2];
  
  update_display(digits);
}

void display_7seg_show_number(uint32_t number)
{
  uint8_t digits[6];
  split_to_6_digits(number, digits);
  update_display(digits);
}

void display_7seg_show_float(float value, uint8_t decimals)
{
  // Ограничиваем диапазон
  if (value < 0)
    value = 0;
  if (value > 999.99f)
    value = 999.99f;
  
  // Умножаем на 10^decimals для отображения
  uint32_t multiplier = 1;
  for (uint8_t i = 0; i < decimals; i++)
  {
    multiplier *= 10;
  }
  
  uint32_t int_value = (uint32_t)(value * multiplier);
  
  // Отображаем на правом дисплее (3 цифры)
  display_7seg_show_right(int_value);
  
  // TODO: Добавить точку, если нужно
  // Для этого нужно модифицировать паттерн цифры, добавив бит DP (7-й бит)
}

void display_7seg_clear(void)
{
  uint8_t empty[6] = {0, 0, 0, 0, 0, 0};
  update_display(empty);
}

// ============================================================================
// ФУНКЦИИ ДЛЯ ПРЯМОГО УПРАВЛЕНИЯ СЕГМЕНТАМИ
// ============================================================================

// Создать паттерн из набора сегментов
// segments_mask - битовая маска сегментов (SEG_A | SEG_B | ...)
uint8_t display_7seg_make_pattern(uint8_t segments_mask)
{
  return segments_mask;
}

// Отобразить паттерн на левом дисплее (3 позиции)
void display_7seg_show_left_segments(uint8_t segments[3])
{
  uint8_t digits[6] = {0, 0, 0, 0, 0, 0};
  digits[0] = segments[0];
  digits[1] = segments[1];
  digits[2] = segments[2];
  update_display(digits);
}

// Отобразить паттерн на правом дисплее (3 позиции)
void display_7seg_show_right_segments(uint8_t segments[3])
{
  uint8_t digits[6] = {0, 0, 0, 0, 0, 0};
  digits[3] = segments[0];
  digits[4] = segments[1];
  digits[5] = segments[2];
  update_display(digits);
}

// Отобразить один паттерн на всех позициях (для теста)
void display_7seg_show_pattern_all(uint8_t pattern)
{
  uint8_t digits[6] = {pattern, pattern, pattern, pattern, pattern, pattern};
  update_display(digits);
}
