#ifndef AQARA_SOCKET_SCREEN_H
#define AQARA_SOCKET_SCREEN_H

#include "display_utils.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Wire.h>

// Структура для данных сенсора
struct SensorData {
  float value;
  bool valid;
  float prev_value;
  bool is_first_update;
  const char *unit;
};

class AqaraSocketScreen : public Adafruit_SSD1306 {
public:
  // Конструктор
  AqaraSocketScreen(int width, int height, TwoWire *wire, int8_t reset_pin);

  // Инициализация экрана
  bool begin(uint8_t i2caddr = 0x3C, bool init_sequence = true);

  // Анимация инициализации
  void showInitAnimation();

  // Отображение одного показателя сенсора
  void showSensorValue(const char *label, const SensorData &sensor, int y_pos,
                       uint8_t text_size, int label_x_pos = 0);

  // Отображение всех 4 показателей на одном экране (для DISPLAY_COUNT == 1)
  void showAllSensors(const SensorData &power, const SensorData &voltage,
                      const SensorData &energy, const SensorData &current);

  // Отображение двух показателей (для DISPLAY_COUNT == 2)
  void showTwoSensors(const SensorData &sensor1, const char *label1,
                      const SensorData &sensor2, const char *label2, int y1,
                      int y2, uint8_t text_size);

  // Отображение одного показателя крупным шрифтом (для DISPLAY_COUNT == 4)
  void showSingleSensor(const SensorData &sensor, const char *label, int y_pos,
                        uint8_t text_size);

private:
  // Отрисовка стрелки
  void drawArrow(int x, int y, bool is_up);

  // Статические данные для стрелок
  static const unsigned char arrow_up_bmp[];
  static const unsigned char arrow_down_bmp[];

  // Индекс для анимации (статический, чтобы был общий для всех экземпляров)
  static int spinner_index;
  // Позиция точки для анимации (0-254: 0-127 туда, 128-254 обратно)
  static int dot_position;
};

#endif // AQARA_SOCKET_SCREEN_H
