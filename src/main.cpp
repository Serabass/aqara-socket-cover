// nanoESP32-C6 - Монитор мощности из Home Assistant
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "display_7seg.h"

static const char *TAG = "HA_POWER_MONITOR";

// ========== MAIN ==========
extern "C" void app_main(void)
{
  ESP_LOGI(TAG, "Инициализация nanoESP32-C6...");
  ESP_LOGI(TAG, "Монитор мощности - работа с дисплеем");

  // Инициализация 7-сегментного дисплея
  display_7seg_init();

  ESP_LOGI(TAG, "Готово! Показываю число 444444");

  // Паттерн цифры 4
  uint8_t digit_4 = SEG_B | SEG_C | SEG_F | SEG_G;

  while (1)
  {
    // Показываем 123456 на всех позициях
    display_7seg_show_number(654321);
    vTaskDelay(pdMS_TO_TICKS(1000)); // Обновление каждую секунду
  }
}
