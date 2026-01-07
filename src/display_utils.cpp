#include "display_utils.h"
#include <cstring>
#include <cstdio>

// Форматирование числа с заменой ведущих нулей на пробелы
// Поддерживает числа до 9999.99
void formatNumber(char *buffer, size_t size, float value) {
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

// Выравнивание числа по точке
void formatNumberAligned(char *output, size_t output_size, float value,
                         int label_len, int dot_char_position) {
  char buffer[16];
  formatNumber(buffer, sizeof(buffer), value);

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

// Получение направления изменения значения
int getChangeDirection(float current, float previous, bool is_first) {
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
