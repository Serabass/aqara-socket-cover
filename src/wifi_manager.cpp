#include "wifi_manager.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "driver/gpio.h"
#include <string.h>

static const char *TAG = "WIFI_MANAGER";

// Встроенный LED на nanoESP32-C6
#define LED_GPIO GPIO_NUM_8

static bool wifiConnected = false;
static void (*statusCallback)(bool) = NULL;

// Управление встроенным LED
static void set_led(bool state)
{
  gpio_set_level(LED_GPIO, state ? 1 : 0);
}

// Инициализация LED
static void led_init(void)
{
  gpio_reset_pin(LED_GPIO);
  gpio_set_level(LED_GPIO, 0);
  gpio_set_direction(LED_GPIO, GPIO_MODE_OUTPUT);
  gpio_set_level(LED_GPIO, 0);
  ESP_LOGI(TAG, "LED инициализирован на GPIO%d (выключен)", LED_GPIO);
}

// Обработчик событий WiFi
static void wifi_event_handler(void *arg, esp_event_base_t event_base,
                               int32_t event_id, void *event_data)
{
  if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START)
  {
    esp_wifi_connect();
    ESP_LOGI(TAG, "WiFi STA старт, подключаюсь...");
  }
  else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED)
  {
    wifiConnected = false;
    set_led(false);
    if (statusCallback)
    {
      statusCallback(false);
    }
    ESP_LOGW(TAG, "WiFi отключен, переподключаюсь...");
    esp_wifi_connect();
  }
  else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP)
  {
    ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
    ESP_LOGI(TAG, "Получен IP адрес:" IPSTR, IP2STR(&event->ip_info.ip));
    wifiConnected = true;
    set_led(true);
    if (statusCallback)
    {
      statusCallback(true);
    }
  }
}

void wifi_manager_init(const char *ssid, const char *password)
{
  // Инициализация LED
  led_init();
  set_led(false);

  ESP_ERROR_CHECK(esp_netif_init());
  ESP_ERROR_CHECK(esp_event_loop_create_default());
  esp_netif_create_default_wifi_sta();

  wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
  ESP_ERROR_CHECK(esp_wifi_init(&cfg));

  ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,
                                                      ESP_EVENT_ANY_ID,
                                                      &wifi_event_handler,
                                                      NULL,
                                                      NULL));
  ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,
                                                      IP_EVENT_STA_GOT_IP,
                                                      &wifi_event_handler,
                                                      NULL,
                                                      NULL));

  wifi_config_t wifi_config = {};
  strncpy((char *)wifi_config.sta.ssid, ssid, sizeof(wifi_config.sta.ssid));
  strncpy((char *)wifi_config.sta.password, password, sizeof(wifi_config.sta.password));
  wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;

  ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
  ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
  ESP_ERROR_CHECK(esp_wifi_start());

  ESP_LOGI(TAG, "WiFi инициализирован, SSID:%s", ssid);
}

bool wifi_manager_is_connected(void)
{
  return wifiConnected;
}

void wifi_manager_set_status_callback(void (*callback)(bool connected))
{
  statusCallback = callback;
}
