#include <Wire.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_GFX.h>
#include <Arduino.h>

// ===== НАСТРОЙКИ =====
// OLED SSD1306 через I2C
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_SDA 21
#define OLED_SCL 22
#define OLED_ADDR 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

void setup() {
    // Инициализация Serial для отладки
    Serial.begin(115200);
    delay(100);
    
    Serial.println("========================================");
    Serial.println("Запуск приложения ESP32 (Arduino)");
    Serial.println("========================================");
    
    // Инициализация I2C
    Wire.begin(OLED_SDA, OLED_SCL);
    
    // Инициализация OLED
    Serial.println("Инициализация OLED SSD1306...");
    if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
        Serial.println("ОШИБКА: Не удалось инициализировать OLED!");
        while (1) delay(1000);
    }
    
    Serial.println("OLED инициализирован успешно!");
    
    // Очистка дисплея
    display.clearDisplay();
    
    // Настройка текста
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    
    // Вывод текста
    display.setCursor(0, 0);
    display.println("Hello World!");
    display.setCursor(0, 16);
    display.println("Arduino OLED");
    display.setCursor(0, 32);
    display.println("SSD1306");
    
    // Отображение на экране
    display.display();
    
    Serial.println("Текст выведен на OLED!");
}

void loop() {
    // Основной цикл - можно добавить логику обновления данных
    delay(1000);
}
