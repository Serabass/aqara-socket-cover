#include "display_lcd1602.h"
// #include "ha_client.h"
// #include "wifi_manager.h"
#include "esp_log.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
// #include <cstring>

static const char *TAG = "MAIN";

// ===== НАСТРОЙКИ =====
// WiFi
// #define WIFI_SSID "MikroTik-9DA0AC"
// #define WIFI_PASSWORD "MYZLMGFPT3"

// Home Assistant
// #define HA_SERVER "192.168.88.13"  // IP адрес Home Assistant
// #define HA_PORT 30123                // Порт Home Assistant
// #define HA_TOKEN "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkZWU1MDMxNTUwOGM0OGVkOGYzOTVjNTJkOTM1YzllMCIsImlhdCI6MTc2NzI3MjUxMywiZXhwIjoyMDgyNjMyNTEzfQ.hSO2cB2AGafJQgpSCoRIS9B2tlsBHoO-Iv83sjfplDs"  // Long-Lived Access Token
// #define HA_ENTITY_ID "sensor.conditioner_socket_power"  // Entity ID сенсора мощности

// LCD1602 прямое подключение (4-битный режим)
#define LCD_RS_PIN GPIO_NUM_21
#define LCD_EN_PIN GPIO_NUM_22
#define LCD_D4_PIN GPIO_NUM_18
#define LCD_D5_PIN GPIO_NUM_19
#define LCD_D6_PIN GPIO_NUM_23
#define LCD_D7_PIN GPIO_NUM_5

// LED убран для тестирования LCD

// Интервал обновления данных (в миллисекундах)
// #define UPDATE_INTERVAL_MS 60000  // 1 минута

// Задача для обновления данных
// static void update_task(void *pvParameters) {
//     float power = 0.0f;
//     bool power_valid = false;
//     
//     while (1) {
//         // Ждем подключения WiFi
//         if (!wifi_manager_is_connected()) {
//             ESP_LOGW(TAG, "WiFi не подключен, ждем...");
//             display_lcd1602_clear();
//             display_lcd1602_set_cursor(0, 0);
//             display_lcd1602_print("WiFi...");
//             vTaskDelay(pdMS_TO_TICKS(5000));
//             continue;
//         }
//         
//         // Получаем данные из Home Assistant
//         ESP_LOGI(TAG, "Запрашиваю данные из Home Assistant...");
//         if (ha_client_fetch_sensor(HA_ENTITY_ID, &power)) {
//             power_valid = true;
//             ESP_LOGI(TAG, "Мощность: %.1f Вт", power);
//             
//             // Отображаем на LCD
//             display_lcd1602_show_power(power);
//             display_lcd1602_set_cursor(1, 0);
//             display_lcd1602_print("HA: OK");
//         } else {
//             ESP_LOGW(TAG, "Ошибка получения данных: %s", ha_client_get_last_error());
//             display_lcd1602_clear();
//             display_lcd1602_set_cursor(0, 0);
//             display_lcd1602_print("Error:");
//             display_lcd1602_set_cursor(1, 0);
//             const char *error = ha_client_get_last_error();
//             if (strlen(error) > 16) {
//                 char short_error[17];
//                 strncpy(short_error, error, 16);
//                 short_error[16] = '\0';
//                 display_lcd1602_print(short_error);
//             } else {
//                 display_lcd1602_print(error);
//             }
//         }
//         
//         vTaskDelay(pdMS_TO_TICKS(UPDATE_INTERVAL_MS));
//     }
// }

extern "C" void app_main(void) {
    // Небольшая задержка для инициализации UART
    vTaskDelay(pdMS_TO_TICKS(100));
    
    ESP_LOGI(TAG, "========================================");
    ESP_LOGI(TAG, "Запуск приложения ESP32");
    ESP_LOGI(TAG, "========================================");
    
    // Инициализация WiFi
    // ESP_LOGI(TAG, "Инициализация WiFi...");
    // wifi_manager_init(WIFI_SSID, WIFI_PASSWORD);
    
    // Инициализация LCD1602
    ESP_LOGI(TAG, "Инициализация LCD1602 (прямое подключение)...");
    if (!display_lcd1602_init(LCD_RS_PIN, LCD_EN_PIN, LCD_D4_PIN, LCD_D5_PIN, LCD_D6_PIN, LCD_D7_PIN)) {
        ESP_LOGE(TAG, "ОШИБКА: Не удалось инициализировать LCD1602!");
        // Продолжаем работу без дисплея
    } else {
        ESP_LOGI(TAG, "LCD1602 инициализирован успешно!");
        vTaskDelay(pdMS_TO_TICKS(100));
        
        ESP_LOGI(TAG, "Очистка дисплея...");
        display_lcd1602_clear();
        vTaskDelay(pdMS_TO_TICKS(100));
        
        ESP_LOGI(TAG, "Вывод текста на LCD...");
        
        // Даём больше времени после clear
        vTaskDelay(pdMS_TO_TICKS(1000));
        
        // Тест: отправляем по одному символу с большими задержками
        ESP_LOGI(TAG, "ТЕСТ: Отправка символов по одному...");
        
        // Первая строка
        display_lcd1602_set_cursor(0, 0);
        vTaskDelay(pdMS_TO_TICKS(200));
        display_lcd1602_print("H");
        vTaskDelay(pdMS_TO_TICKS(500));
        display_lcd1602_print("e");
        vTaskDelay(pdMS_TO_TICKS(500));
        display_lcd1602_print("l");
        vTaskDelay(pdMS_TO_TICKS(500));
        display_lcd1602_print("l");
        vTaskDelay(pdMS_TO_TICKS(500));
        display_lcd1602_print("o");
        vTaskDelay(pdMS_TO_TICKS(1000));
        
        // Вторая строка
        display_lcd1602_set_cursor(1, 0);
        vTaskDelay(pdMS_TO_TICKS(200));
        display_lcd1602_print("Test");
        vTaskDelay(pdMS_TO_TICKS(1000));
        
        ESP_LOGI(TAG, "Текст отправлен на LCD");
    }
    
    // Инициализация Home Assistant клиента
    // ESP_LOGI(TAG, "Инициализация Home Assistant клиента...");
    // ha_client_init(HA_SERVER, HA_PORT, HA_TOKEN);
    
    // Создаем задачу для обновления данных
    // xTaskCreate(update_task, "update_task", 4096, NULL, 5, NULL);
    
    ESP_LOGI(TAG, "Приложение запущено");
    
    // Основной цикл
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
