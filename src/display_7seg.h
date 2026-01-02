#ifndef DISPLAY_7SEG_H
#define DISPLAY_7SEG_H

#include <stdint.h>

// Инициализация 7-сегментного дисплея
void display_7seg_init(void);

// Отобразить число на левом дисплее (0-999)
void display_7seg_show_left(uint32_t number);

// Отобразить число на правом дисплее (0-999)
void display_7seg_show_right(uint32_t number);

// Отобразить на левом дисплее напрямую массив из 3 байтов (для тестирования)
void display_7seg_show_left_direct(uint8_t digits[3]);

// Отобразить на правом дисплее напрямую массив из 3 байтов (для тестирования)
void display_7seg_show_right_direct(uint8_t digits[3]);

// Отобразить напрямую массив из 6 байтов (для тестирования всех позиций)
void display_7seg_show_direct(uint8_t digits[6]);

// Отобразить число на обоих дисплеях (0-999999)
// Левая часть (старшие 3 цифры) и правая часть (младшие 3 цифры)
void display_7seg_show_number(uint32_t number);

// Отобразить число с плавающей точкой (например, 123.45)
void display_7seg_show_float(float value, uint8_t decimals);

// Очистить оба дисплея
void display_7seg_clear(void);

// ============================================================================
// ФУНКЦИИ ДЛЯ ПРЯМОГО УПРАВЛЕНИЯ СЕГМЕНТАМИ (для отладки)
// ============================================================================

// Маска сегментов (биты: A=0, B=1, C=2, D=3, E=4, F=5, G=6, DP=7)
#define SEG_A  (1 << 0)  // 0b00000001
#define SEG_B  (1 << 1)  // 0b00000010
#define SEG_C  (1 << 2)  // 0b00000100
#define SEG_D  (1 << 3)  // 0b00001000
#define SEG_E  (1 << 4)  // 0b00010000
#define SEG_F  (1 << 5)  // 0b00100000
#define SEG_G  (1 << 6)  // 0b01000000
#define SEG_DP (1 << 7)  // 0b10000000
 
// Создать паттерн из набора сегментов
// Пример: display_7seg_make_pattern(SEG_A | SEG_B | SEG_C) - включит A, B, C
uint8_t display_7seg_make_pattern(uint8_t segments_mask);

// Отобразить паттерн на левом дисплее (3 позиции)
// segments[0] - левая позиция, segments[1] - средняя, segments[2] - правая
void display_7seg_show_left_segments(uint8_t segments[3]);

// Отобразить паттерн на правом дисплее (3 позиции)
// segments[0] - левая позиция, segments[1] - средняя, segments[2] - правая
void display_7seg_show_right_segments(uint8_t segments[3]);

// Отобразить один паттерн на всех позициях (для теста)
void display_7seg_show_pattern_all(uint8_t pattern);

#endif // DISPLAY_7SEG_H

