// ===== СЕКРЕТЫ И КОНФИГУРАЦИЯ =====
// ВНИМАНИЕ: Этот файл - шаблон. Скопируй его в secrets.h и заполни своими значениями
// Файл secrets.h уже добавлен в .gitignore и не попадет в git

// WiFi настройки
// Для Wokwi используй "Wokwi-GUEST" без пароля
// Для реального ESP32 измени на свои данные
// Раскомментируй #define WOKWI для работы в Wokwi симуляторе
#if defined(WOKWI)
#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""
#else
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#endif

// Home Assistant настройки
#define HA_SERVER "192.168.1.100" // IP адрес Home Assistant
#define HA_PORT 8123              // Порт Home Assistant (обычно 8123)
#define HA_TOKEN "YOUR_LONG_LIVED_ACCESS_TOKEN" // Long-Lived Access Token из Home Assistant

// Entity ID сенсоров
#define HA_ENTITY_NAME "conditioner_socket"
