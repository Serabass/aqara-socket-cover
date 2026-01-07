#include "AqaraSocketScreen.h"
#include "display_utils.h"
#include <Arduino.h>
#include <cstring>

// Статические данные для стрелок
const unsigned char AqaraSocketScreen::arrow_up_bmp[] = {
    0B00011000, 0B00111100, 0B01111110, 0B11111111,
    0B00011000, 0B00011000, 0B00011000, 0B00000000};

const unsigned char AqaraSocketScreen::arrow_down_bmp[] = {
    0B00011000, 0B00011000, 0B00011000, 0B11111111,
    0B01111110, 0B00111100, 0B00011000, 0B00000000};

// Статический индекс для анимации
int AqaraSocketScreen::spinner_index = 0;

// Конструктор
AqaraSocketScreen::AqaraSocketScreen(int width, int height, TwoWire *wire,
                                     int8_t reset_pin)
    : Adafruit_SSD1306(width, height, wire, reset_pin) {}

// Инициализация экрана
bool AqaraSocketScreen::begin(uint8_t i2caddr, bool init_sequence) {
  return Adafruit_SSD1306::begin(SSD1306_SWITCHCAPVCC, i2caddr, init_sequence);
}

// Анимация инициализации (вращающийся индикатор)
void AqaraSocketScreen::showInitAnimation() {
  const char *spinner_chars = "|/-\\"; // Символы для анимации

  clearDisplay();
  setTextSize(2);
  setTextColor(SSD1306_WHITE);

  // Центрируем анимацию
  setCursor(50, 20);
  print(spinner_chars[spinner_index]);

  spinner_index = (spinner_index + 1) % 4; // Цикл через 4 символа
  display();
}

// Отрисовка стрелки
void AqaraSocketScreen::drawArrow(int x, int y, bool is_up) {
  drawBitmap(x, y, is_up ? arrow_up_bmp : arrow_down_bmp, 8, 8, SSD1306_WHITE);
}

// Отображение одного показателя сенсора
void AqaraSocketScreen::showSensorValue(const char *label,
                                        const SensorData &sensor, int y_pos,
                                        uint8_t text_size, int label_x_pos) {
  char buffer[32];
  char full_text[32];

  // Формируем полный текст значения
  if (sensor.valid) {
    formatNumber(buffer, sizeof(buffer), sensor.value);
    snprintf(full_text, sizeof(full_text), "%s %s", buffer, sensor.unit);
  } else {
    strncpy(full_text, "    .00", sizeof(full_text));
  }

  // Значение - центрируем по горизонтали
  setTextSize(text_size);
  int text_width =
      strlen(full_text) * 6 * text_size; // Примерная ширина символа 6 пикселей
  int x_pos = (128 - text_width) / 2;    // Центрируем на экране шириной 128
  if (x_pos < 0)
    x_pos = 0; // Не выходим за границы
  setCursor(x_pos, y_pos);
  print(full_text);

  // Показываем стрелку изменения справа от текста
  int change_dir = getChangeDirection(sensor.value, sensor.prev_value,
                                      sensor.is_first_update);
  if (change_dir != 0) {
    int arrow_x =
        x_pos + text_width + 2; // Справа от текста с небольшим отступом
    if (arrow_x + 8 <= 128) {   // Проверяем, что стрелка поместится
      drawArrow(arrow_x, y_pos, change_dir == 1);
    }
  }
}

// Отображение всех 4 показателей на одном экране (для DISPLAY_COUNT == 1)
void AqaraSocketScreen::showAllSensors(const SensorData &power,
                                       const SensorData &voltage,
                                       const SensorData &energy,
                                       const SensorData &current) {
  clearDisplay();
  setTextSize(1);
  setTextColor(SSD1306_WHITE);

  char aligned_buffer[32];
  int line_height = 16;      // Высота строки (64 / 4 = 16)
  int dot_char_position = 8; // Позиция точки в символах от начала строки

  // POWER - только значение с единицей
  setCursor(0, 0);
  if (power.valid) {
    formatNumberAligned(aligned_buffer, sizeof(aligned_buffer), power.value, 0,
                        dot_char_position);
    print(aligned_buffer);
    print(" W");
    int change_dir = getChangeDirection(power.value, power.prev_value,
                                        power.is_first_update);
    if (change_dir != 0) {
      drawArrow(100, 0, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4; // 4 символа для " .00"
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      print(" ");
    print("    .00 W");
  }

  // VOLTAGE - только значение с единицей
  setCursor(0, line_height);
  if (voltage.valid) {
    formatNumberAligned(aligned_buffer, sizeof(aligned_buffer), voltage.value,
                        0, dot_char_position);
    print(aligned_buffer);
    print(" V");
    int change_dir = getChangeDirection(voltage.value, voltage.prev_value,
                                        voltage.is_first_update);
    if (change_dir != 0) {
      drawArrow(100, line_height, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4;
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      print(" ");
    print("    .00 V");
  }

  // ENERGY - только значение с единицей
  setCursor(0, line_height * 2);
  if (energy.valid) {
    formatNumberAligned(aligned_buffer, sizeof(aligned_buffer), energy.value, 0,
                        dot_char_position);
    print(aligned_buffer);
    print(" kWh");
    int change_dir = getChangeDirection(energy.value, energy.prev_value,
                                        energy.is_first_update);
    if (change_dir != 0) {
      drawArrow(100, line_height * 2, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4;
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      print(" ");
    print("    .00 kWh");
  }

  // CURRENT - только значение с единицей
  setCursor(0, line_height * 3);
  if (current.valid) {
    formatNumberAligned(aligned_buffer, sizeof(aligned_buffer), current.value,
                        0, dot_char_position);
    print(aligned_buffer);
    print(" A");
    int change_dir = getChangeDirection(current.value, current.prev_value,
                                        current.is_first_update);
    if (change_dir != 0) {
      drawArrow(100, line_height * 3, change_dir == 1);
    }
  } else {
    int spaces = dot_char_position - 4;
    if (spaces < 0)
      spaces = 0;
    for (int i = 0; i < spaces; i++)
      print(" ");
    print("    .00 A");
  }

  display();
}

// Отображение двух показателей (для DISPLAY_COUNT == 2)
void AqaraSocketScreen::showTwoSensors(const SensorData &sensor1,
                                       const char *label1,
                                       const SensorData &sensor2,
                                       const char *label2, int y1, int y2,
                                       uint8_t text_size) {
  clearDisplay();
  setTextSize(text_size);
  setTextColor(SSD1306_WHITE);
  showSensorValue(label1, sensor1, y1, text_size, 0);
  showSensorValue(label2, sensor2, y2, text_size, 70);
  display();
}

// Отображение одного показателя крупным шрифтом (для DISPLAY_COUNT == 4)
void AqaraSocketScreen::showSingleSensor(const SensorData &sensor,
                                         const char *label, int y_pos,
                                         uint8_t text_size) {
  clearDisplay();
  setTextSize(text_size);
  setTextColor(SSD1306_WHITE);
  showSensorValue(label, sensor, y_pos, text_size, 0);
  display();
}
