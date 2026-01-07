#ifndef DISPLAY_UTILS_H
#define DISPLAY_UTILS_H

#include <cstddef>

// Форматирование числа с заменой ведущих нулей на пробелы
// Поддерживает числа до 9999.99
void formatNumber(char *buffer, size_t size, float value);

// Выравнивание числа по точке
// label_len - длина метки (например, "POWER: " = 7)
// dot_char_position - позиция точки в символах от начала строки (после метки)
// Возвращает строку с пробелами перед числом, чтобы точка была на фиксированной
// позиции
void formatNumberAligned(char *output, size_t output_size, float value,
                         int label_len, int dot_char_position);

// Получение направления изменения значения
// Возвращает: 1 = вверх, -1 = вниз, 0 = без изменений
int getChangeDirection(float current, float previous, bool is_first);

#endif // DISPLAY_UTILS_H
