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

  ESP_LOGI(TAG, "Готово! Перебираю все сегменты на каждой позиции");

  // Массив всех сегментов
  uint8_t segments[] = {
    SEG_A,   // 0
    SEG_B,   // 1
    SEG_C,   // 2
    SEG_D,   // 3
    SEG_E,   // 4
    SEG_F,   // 5
    SEG_G,   // 6
    SEG_DP   // 7
  };
  
  const char* segment_names[] = {
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "DP"
  };

  while (1)
  {
    // Для каждой позиции (0-5)
    for (int pos = 0; pos < 6; pos++)
    {
      ESP_LOGI(TAG, "Позиция %d", pos);
      
      // Показываем каждый сегмент по очереди на этой позиции
      for (int seg = 0; seg < 8; seg++)
      {
        uint8_t digits[6] = {0, 0, 0, 0, 0, 0}; // Все позиции пустые
        digits[pos] = segments[seg];            // На текущей позиции - сегмент
        
        display_7seg_show_direct(digits);
        ESP_LOGI(TAG, "Позиция %d: сегмент %s", pos, segment_names[seg]);
        vTaskDelay(pdMS_TO_TICKS(500)); // Задержка 500мс
      }
      
      // Пауза между позициями
      vTaskDelay(pdMS_TO_TICKS(500));
    }
    
    // Пауза перед повторением цикла
    ESP_LOGI(TAG, "--- Цикл завершен, начинаю заново ---");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
