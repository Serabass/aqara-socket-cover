#include "ha_client.h"
#include "wifi_manager.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "ArduinoJson.h"
#include <string.h>

static const char *TAG = "HA_CLIENT";

static char ha_server[64] = "";
static int ha_port = 0;
static char ha_token[256] = "";
static char lastError[64] = "";
static char httpResponseBuffer[1024];
static size_t httpResponseLen = 0;

// HTTP обработчик
static esp_err_t http_event_handler(esp_http_client_event_t *evt)
{
  switch (evt->event_id)
  {
  case HTTP_EVENT_ERROR:
    ESP_LOGD(TAG, "HTTP_EVENT_ERROR");
    break;
  case HTTP_EVENT_ON_CONNECTED:
    ESP_LOGD(TAG, "HTTP_EVENT_ON_CONNECTED");
    httpResponseLen = 0;
    break;
  case HTTP_EVENT_HEADER_SENT:
    ESP_LOGD(TAG, "HTTP_EVENT_HEADER_SENT");
    break;
  case HTTP_EVENT_ON_HEADER:
    ESP_LOGD(TAG, "HTTP_EVENT_ON_HEADER, key=%s, value=%s", evt->header_key, evt->header_value);
    break;
  case HTTP_EVENT_ON_DATA:
    ESP_LOGD(TAG, "HTTP_EVENT_ON_DATA, len=%d", evt->data_len);
    if (!esp_http_client_is_chunked_response(evt->client))
    {
      if (httpResponseLen + evt->data_len < sizeof(httpResponseBuffer))
      {
        memcpy(httpResponseBuffer + httpResponseLen, evt->data, evt->data_len);
        httpResponseLen += evt->data_len;
      }
    }
    break;
  case HTTP_EVENT_ON_FINISH:
    ESP_LOGD(TAG, "HTTP_EVENT_ON_FINISH");
    if (httpResponseLen > 0)
    {
      httpResponseBuffer[httpResponseLen] = '\0';
      ESP_LOGI(TAG, "Получен ответ (len=%d): %s", httpResponseLen, httpResponseBuffer);
    }
    else
    {
      ESP_LOGW(TAG, "HTTP ответ пустой (len=0)");
    }
    break;
  case HTTP_EVENT_DISCONNECTED:
    ESP_LOGD(TAG, "HTTP_EVENT_DISCONNECTED");
    break;
  default:
    break;
  }
  return ESP_OK;
}

void ha_client_init(const char *server, int port, const char *token)
{
  strncpy(ha_server, server, sizeof(ha_server) - 1);
  ha_port = port;
  strncpy(ha_token, token, sizeof(ha_token) - 1);
  ESP_LOGI(TAG, "HA клиент инициализирован: %s:%d", server, port);
}

bool ha_client_fetch_sensor(const char *entity_id, float *value)
{
  if (!wifi_manager_is_connected())
  {
    ESP_LOGW(TAG, "WiFi не подключен!");
    strcpy(lastError, "WiFi не подключен");
    return false;
  }

  if (value == NULL)
  {
    ESP_LOGE(TAG, "Указатель value равен NULL");
    return false;
  }

  char url[256];
  snprintf(url, sizeof(url), "http://%s:%d/api/states/%s", ha_server, ha_port, entity_id);

  ESP_LOGI(TAG, "Запрос: %s", url);

  esp_http_client_config_t config = {};
  config.url = url;
  config.event_handler = http_event_handler;
  config.timeout_ms = 10000;
  esp_http_client_handle_t client = esp_http_client_init(&config);

  if (client == NULL)
  {
    ESP_LOGE(TAG, "Ошибка инициализации HTTP клиента");
    strcpy(lastError, "Ошибка инициализации");
    return false;
  }

  httpResponseLen = 0; // Сбрасываем буфер

  esp_http_client_set_method(client, HTTP_METHOD_GET);

  char auth_header[256];
  int len = snprintf(auth_header, sizeof(auth_header), "Bearer %s", ha_token);
  if (len >= sizeof(auth_header))
  {
    ESP_LOGE(TAG, "Заголовок Authorization слишком длинный!");
    esp_http_client_cleanup(client);
    strcpy(lastError, "Ошибка заголовка");
    return false;
  }

  esp_err_t header_err = esp_http_client_set_header(client, "Authorization", auth_header);
  if (header_err != ESP_OK)
  {
    ESP_LOGE(TAG, "Ошибка установки заголовка Authorization: %s", esp_err_to_name(header_err));
    esp_http_client_cleanup(client);
    strcpy(lastError, "Ошибка заголовка");
    return false;
  }

  esp_http_client_set_header(client, "Content-Type", "application/json");

  esp_err_t err = esp_http_client_perform(client);

  bool success = false;

  if (err == ESP_OK)
  {
    int status_code = esp_http_client_get_status_code(client);
    ESP_LOGI(TAG, "HTTP статус: %d", status_code);
    if (status_code == 200)
    {
      if (httpResponseLen > 0)
      {
        httpResponseBuffer[httpResponseLen] = '\0';

        // Парсим JSON ответ
        StaticJsonDocument<1024> doc;
        DeserializationError json_error = deserializeJson(doc, httpResponseBuffer);

        if (!json_error)
        {
          const char *state = doc["state"];
          if (state != nullptr)
          {
            // Проверяем на невалидные значения
            if (strcmp(state, "unavailable") == 0 || strcmp(state, "unknown") == 0 || strlen(state) == 0)
            {
              ESP_LOGW(TAG, "State содержит невалидное значение: '%s'", state);
              strcpy(lastError, "Невалидное значение");
            }
            else
            {
              *value = atof(state);
              ESP_LOGI(TAG, "Значение распарсено: %.1f", *value);
              strcpy(lastError, "");
              success = true;
            }
          }
          else
          {
            ESP_LOGE(TAG, "Поле 'state' не найдено в JSON");
            strcpy(lastError, "Нет данных");
          }
        }
        else
        {
          ESP_LOGE(TAG, "Ошибка парсинга JSON: %s", json_error.c_str());
          strcpy(lastError, "Ошибка JSON");
        }
      }
      else
      {
        ESP_LOGW(TAG, "HTTP ответ пустой");
        strcpy(lastError, "Пустой ответ");
      }
    }
    else
    {
      snprintf(lastError, sizeof(lastError), "HTTP %d", status_code);
    }
  }
  else
  {
    ESP_LOGE(TAG, "HTTP ошибка выполнения: %s", esp_err_to_name(err));
    strcpy(lastError, "HTTP ошибка");
  }

  esp_http_client_cleanup(client);
  return success;
}

const char *ha_client_get_last_error(void)
{
  return lastError;
}

