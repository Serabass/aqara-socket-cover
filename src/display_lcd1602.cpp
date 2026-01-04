#include "display_lcd1602.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_rom_sys.h"
#include <string.h>
#include <stdio.h>

static const char *TAG = "LCD1602";

// GPIO пины
static gpio_num_t lcd_rs_pin = GPIO_NUM_NC;
static gpio_num_t lcd_en_pin = GPIO_NUM_NC;
static gpio_num_t lcd_d4_pin = GPIO_NUM_NC;
static gpio_num_t lcd_d5_pin = GPIO_NUM_NC;
static gpio_num_t lcd_d6_pin = GPIO_NUM_NC;
static gpio_num_t lcd_d7_pin = GPIO_NUM_NC;
static bool backlight_state = true;

// LCD команды
#define LCD_CLEARDISPLAY   0x01
#define LCD_RETURNHOME     0x02
#define LCD_ENTRYMODESET   0x04
#define LCD_DISPLAYCONTROL 0x08
#define LCD_CURSORSHIFT    0x10
#define LCD_FUNCTIONSET    0x20
#define LCD_SETCGRAMADDR   0x40
#define LCD_SETDDRAMADDR   0x80

// Флаги для LCD_ENTRYMODESET
#define LCD_ENTRYRIGHT          0x00
#define LCD_ENTRYLEFT           0x02
#define LCD_ENTRYSHIFTINCREMENT 0x01
#define LCD_ENTRYSHIFTDECREMENT 0x00

// Флаги для LCD_DISPLAYCONTROL
#define LCD_DISPLAYON  0x04
#define LCD_DISPLAYOFF 0x00
#define LCD_CURSORON   0x02
#define LCD_CURSOROFF  0x00
#define LCD_BLINKON    0x01
#define LCD_BLINKOFF  0x00

// Флаги для LCD_FUNCTIONSET
#define LCD_8BITMODE 0x10
#define LCD_4BITMODE 0x00
#define LCD_2LINE    0x08
#define LCD_1LINE    0x00
#define LCD_5x10DOTS 0x04
#define LCD_5x8DOTS  0x00

// Внутренние функции
static void lcd_write_nibble(uint8_t data);
static void lcd_write_byte(uint8_t data, uint8_t mode);
static void lcd_send_command(uint8_t cmd);
static void lcd_send_data(uint8_t data);

// Задержка в микросекундах
static void delay_us(uint32_t us) {
    if (us < 1000) {
        esp_rom_delay_us(us);
    } else {
        vTaskDelay(pdMS_TO_TICKS((us + 999) / 1000));
    }
}

// Отправка nibble (4 бита) на пины D4-D7
static void lcd_write_nibble(uint8_t data) {
    gpio_set_level(lcd_d4_pin, (data >> 0) & 0x01);
    gpio_set_level(lcd_d5_pin, (data >> 1) & 0x01);
    gpio_set_level(lcd_d6_pin, (data >> 2) & 0x01);
    gpio_set_level(lcd_d7_pin, (data >> 3) & 0x01);
    
    delay_us(1);
    
    // Strobe EN
    gpio_set_level(lcd_en_pin, 1);
    delay_us(1);  // Минимум 450ns
    gpio_set_level(lcd_en_pin, 0);
    delay_us(50);  // Задержка между nibbles
}

// Отправка байта в LCD
static void lcd_write_byte(uint8_t data, uint8_t mode) {
    // Установить RS (0 = команда, 1 = данные)
    gpio_set_level(lcd_rs_pin, mode);
    delay_us(1);
    
    // Отправить старший nibble
    lcd_write_nibble(data >> 4);
    
    // Отправить младший nibble
    lcd_write_nibble(data & 0x0F);
    
    delay_us(100);  // Задержка после команды
}

// Отправка команды
static void lcd_send_command(uint8_t cmd) {
    lcd_write_byte(cmd, 0);
}

// Отправка данных
static void lcd_send_data(uint8_t data) {
    lcd_write_byte(data, 1);
}

// Инициализация GPIO пина
static void init_gpio_pin(gpio_num_t pin) {
    gpio_reset_pin(pin);
    gpio_set_direction(pin, GPIO_MODE_OUTPUT);
    gpio_set_level(pin, 0);
}

// Инициализация LCD1602
bool display_lcd1602_init(gpio_num_t rs_pin, gpio_num_t en_pin, 
                          gpio_num_t d4_pin, gpio_num_t d5_pin, 
                          gpio_num_t d6_pin, gpio_num_t d7_pin) {
    ESP_LOGI(TAG, "Инициализация LCD1602 (прямое подключение)");
    ESP_LOGI(TAG, "RS=%d, EN=%d, D4=%d, D5=%d, D6=%d, D7=%d", 
             rs_pin, en_pin, d4_pin, d5_pin, d6_pin, d7_pin);
    
    // Сохраняем пины
    lcd_rs_pin = rs_pin;
    lcd_en_pin = en_pin;
    lcd_d4_pin = d4_pin;
    lcd_d5_pin = d5_pin;
    lcd_d6_pin = d6_pin;
    lcd_d7_pin = d7_pin;
    
    // Инициализация GPIO
    init_gpio_pin(lcd_rs_pin);
    init_gpio_pin(lcd_en_pin);
    init_gpio_pin(lcd_d4_pin);
    init_gpio_pin(lcd_d5_pin);
    init_gpio_pin(lcd_d6_pin);
    init_gpio_pin(lcd_d7_pin);
    
    // Инициализация LCD (последовательность из datasheet для 4-битного режима)
    vTaskDelay(pdMS_TO_TICKS(50));  // Ждем стабилизации питания
    
    // Первая последовательность инициализации (0x03)
    lcd_write_nibble(0x03);
    vTaskDelay(pdMS_TO_TICKS(5));  // Ждем >4.1ms
    
    // Вторая последовательность (0x03)
    lcd_write_nibble(0x03);
    delay_us(200);  // Ждем >100us
    
    // Третья последовательность (0x03)
    lcd_write_nibble(0x03);
    delay_us(200);  // Ждем >100us
    
    // Переключение в 4-битный режим (0x02)
    lcd_write_nibble(0x02);
    delay_us(200);  // Ждем >100us
    
    // Теперь используем нормальные команды
    lcd_send_command(LCD_FUNCTIONSET | LCD_2LINE | LCD_5x8DOTS | LCD_4BITMODE);
    vTaskDelay(pdMS_TO_TICKS(5));
    
    lcd_send_command(LCD_DISPLAYCONTROL | LCD_DISPLAYON | LCD_CURSOROFF | LCD_BLINKOFF);
    vTaskDelay(pdMS_TO_TICKS(5));
    
    lcd_send_command(LCD_CLEARDISPLAY);
    vTaskDelay(pdMS_TO_TICKS(5));  // Clear display требует >1.52ms
    
    lcd_send_command(LCD_ENTRYMODESET | LCD_ENTRYLEFT | LCD_ENTRYSHIFTDECREMENT);
    vTaskDelay(pdMS_TO_TICKS(5));
    
    ESP_LOGI(TAG, "LCD1602 инициализирован успешно");
    return true;
}

// Очистить дисплей
void display_lcd1602_clear(void) {
    lcd_send_command(LCD_CLEARDISPLAY);
    vTaskDelay(pdMS_TO_TICKS(2));  // Clear display требует >1.52ms
}

// Установить курсор
void display_lcd1602_set_cursor(uint8_t row, uint8_t col) {
    uint8_t row_offsets[] = {0x00, 0x40};
    if (row > 1) row = 1;
    if (col > 15) col = 15;
    lcd_send_command(LCD_SETDDRAMADDR | (col + row_offsets[row]));
}

// Вывести строку
void display_lcd1602_print(const char *str) {
    if (str == NULL) {
        ESP_LOGW(TAG, "display_lcd1602_print: получен NULL указатель");
        return;
    }
    size_t len = strlen(str);
    ESP_LOGD(TAG, "Вывод строки на LCD: '%s' (len=%d)", str, len);
    for (size_t i = 0; i < len && i < 32; i++) {
        lcd_send_data((uint8_t)str[i]);
        delay_us(50);  // Небольшая задержка между символами
    }
}

// Вывести число
void display_lcd1602_print_number(uint32_t number) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%lu", number);
    display_lcd1602_print(buf);
}

// Вывести число с плавающей точкой
void display_lcd1602_print_float(float value, uint8_t decimals) {
    char buf[32];
    char format[8];
    snprintf(format, sizeof(format), "%%.%df", decimals);
    snprintf(buf, sizeof(buf), format, value);
    display_lcd1602_print(buf);
}

// Управление подсветкой (заглушка, подсветка всегда включена при прямом подключении)
void display_lcd1602_backlight(bool on) {
    backlight_state = on;
    // При прямом подключении подсветка управляется через пин A (анод)
    // Обычно подключена к питанию, так что просто запоминаем состояние
}

// Отобразить мощность
void display_lcd1602_show_power(float power) {
    display_lcd1602_clear();
    display_lcd1602_set_cursor(0, 0);
    display_lcd1602_print("Power:");
    display_lcd1602_set_cursor(0, 7);
    display_lcd1602_print_float(power, 1);
    display_lcd1602_set_cursor(0, 12);
    display_lcd1602_print("W");
}

// Отобразить статус
void display_lcd1602_show_status(const char *status) {
    display_lcd1602_set_cursor(1, 0);
    display_lcd1602_print("                "); // Очистить строку
    display_lcd1602_set_cursor(1, 0);
    display_lcd1602_print(status);
}
