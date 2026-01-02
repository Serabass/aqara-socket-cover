#ifndef HA_CLIENT_H
#define HA_CLIENT_H

#include <stdbool.h>

// Инициализация HA клиента
void ha_client_init(const char *server, int port, const char *token);

// Получить значение сенсора
bool ha_client_fetch_sensor(const char *entity_id, float *value);

// Получить последнюю ошибку
const char *ha_client_get_last_error(void);

#endif // HA_CLIENT_H

