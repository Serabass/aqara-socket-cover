#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <stdbool.h>

// Инициализация WiFi
void wifi_manager_init(const char *ssid, const char *password);

// Получить статус подключения
bool wifi_manager_is_connected(void);

// Получить IP адрес
const char* wifi_manager_get_ip(void);

#endif // WIFI_MANAGER_H
