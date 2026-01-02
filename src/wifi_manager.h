#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <stdbool.h>

// Инициализация WiFi
void wifi_manager_init(const char *ssid, const char *password);

// Получить статус подключения
bool wifi_manager_is_connected(void);

// Установить callback для изменения статуса подключения
void wifi_manager_set_status_callback(void (*callback)(bool connected));

#endif // WIFI_MANAGER_H

