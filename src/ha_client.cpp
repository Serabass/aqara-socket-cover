#include "ha_client.h"
#include "wifi_manager.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Arduino.h>
#include <string.h>

static char ha_server[64] = "";
static int ha_port = 0;
static char ha_token[256] = "";
static char lastError[128] = "";

void ha_client_init(const char *server, int port, const char *token) {
    strncpy(ha_server, server, sizeof(ha_server) - 1);
    ha_port = port;
    strncpy(ha_token, token, sizeof(ha_token) - 1);
    Serial.printf("HA клиент инициализирован: %s:%d\n", server, port);
}

bool ha_client_fetch_sensor(const char *entity_id, float *value) {
    if (!wifi_manager_is_connected()) {
        Serial.println("WiFi не подключен!");
        strcpy(lastError, "WiFi не подключен");
        return false;
    }

    if (value == NULL) {
        Serial.println("Указатель value равен NULL");
        return false;
    }

    HTTPClient http;
    char url[256];
    snprintf(url, sizeof(url), "http://%s:%d/api/states/%s", ha_server, ha_port, entity_id);

    Serial.print("Запрос: ");
    Serial.println(url);

    http.begin(url);
    http.addHeader("Authorization", String("Bearer ") + ha_token);
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(10000);

    int httpCode = http.GET();

    bool success = false;

    if (httpCode > 0) {
        Serial.printf("HTTP статус: %d\n", httpCode);
        
        if (httpCode == HTTP_CODE_OK) {
            String payload = http.getString();
            Serial.print("Ответ: ");
            Serial.println(payload);

            // Парсим JSON
            StaticJsonDocument<1024> doc;
            DeserializationError error = deserializeJson(doc, payload);

            if (!error) {
                const char* state = doc["state"];
                if (state != nullptr) {
                    // Проверяем на невалидные значения
                    if (strcmp(state, "unavailable") == 0 || 
                        strcmp(state, "unknown") == 0 || 
                        strlen(state) == 0) {
                        Serial.printf("State содержит невалидное значение: '%s'\n", state);
                        strcpy(lastError, "Невалидное значение");
                    } else {
                        *value = atof(state);
                        Serial.printf("Значение распарсено: %.1f\n", *value);
                        strcpy(lastError, "");
                        success = true;
                    }
                } else {
                    Serial.println("Поле 'state' не найдено в JSON");
                    strcpy(lastError, "Нет данных");
                }
            } else {
                Serial.print("Ошибка парсинга JSON: ");
                Serial.println(error.c_str());
                strcpy(lastError, "Ошибка JSON");
            }
        } else {
            snprintf(lastError, sizeof(lastError), "HTTP %d", httpCode);
        }
    } else {
        Serial.printf("HTTP ошибка: %s\n", http.errorToString(httpCode).c_str());
        strcpy(lastError, "HTTP ошибка");
    }

    http.end();
    return success;
}

const char *ha_client_get_last_error(void) {
    return lastError;
}
