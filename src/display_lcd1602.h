#ifndef DISPLAY_LCD1602_H
#define DISPLAY_LCD1602_H

#include <stdint.h>
#include <stdbool.h>
#include "driver/gpio.h"

// Инициализация LCD1602 дисплея (прямое подключение, 4-битный режим)
// rs_pin - GPIO пин для RS (Register Select)
// en_pin - GPIO пин для EN (Enable)
// d4_pin - GPIO пин для D4
// d5_pin - GPIO пин для D5
// d6_pin - GPIO пин для D6
// d7_pin - GPIO пин для D7
bool display_lcd1602_init(gpio_num_t rs_pin, gpio_num_t en_pin, 
                          gpio_num_t d4_pin, gpio_num_t d5_pin, 
                          gpio_num_t d6_pin, gpio_num_t d7_pin);

// Очистить дисплей
void display_lcd1602_clear(void);

// Установить курсор на позицию (row: 0-1, col: 0-15)
void display_lcd1602_set_cursor(uint8_t row, uint8_t col);

// Вывести строку на дисплей
void display_lcd1602_print(const char *str);

// Вывести число на дисплей
void display_lcd1602_print_number(uint32_t number);

// Вывести число с плавающей точкой
void display_lcd1602_print_float(float value, uint8_t decimals);

// Включить/выключить подсветку
void display_lcd1602_backlight(bool on);

// Отобразить мощность (форматированный вывод)
void display_lcd1602_show_power(float power);

// Отобразить статус подключения
void display_lcd1602_show_status(const char *status);

#endif // DISPLAY_LCD1602_H
