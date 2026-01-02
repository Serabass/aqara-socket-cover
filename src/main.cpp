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

  ESP_LOGI(TAG, "Готово! Показываю все сегменты по очереди");

  // Массив всех сегментов для тестирования
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
    "SEG_A",
    "SEG_B",
    "SEG_C",
    "SEG_D",
    "SEG_E",
    "SEG_F",
    "SEG_G",
    "SEG_DP"
  };

  while (1)
  {
    // Показываем каждый сегмент по очереди на всех позициях
    for (int i = 0; i < 8; i++)
    {
      display_7seg_show_pattern_all(segments[i]);
      ESP_LOGI(TAG, "Показываю сегмент %s на всех позициях", segment_names[i]);
      vTaskDelay(pdMS_TO_TICKS(1000)); // Задержка 1 секунда
    }
    
    // Небольшая пауза перед повторением цикла
    ESP_LOGI(TAG, "--- Цикл завершен, начинаю заново ---");
    vTaskDelay(pdMS_TO_TICKS(500));
  }
}
