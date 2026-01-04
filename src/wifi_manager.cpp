#include "wifi_manager.h"
#include <WiFi.h>
#include <Arduino.h>

static bool wifiConnected = false;
static char ipAddress[16] = "";

void wifi_manager_init(const char *ssid, const char *password) {
    Serial.print("Подключение к WiFi: ");
    Serial.println(ssid);
    
    WiFi.mode(WIFI_STA);
    
    // Для Wokwi используем канал 6 для ускорения подключения
    if (strcmp(ssid, "Wokwi-GUEST") == 0) {
        WiFi.begin(ssid, password, 6);
    } else {
        WiFi.begin(ssid, password);
    }
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 30) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        IPAddress ip = WiFi.localIP();
        snprintf(ipAddress, sizeof(ipAddress), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
        Serial.println();
        Serial.print("WiFi подключен! IP: ");
        Serial.println(ipAddress);
    } else {
        wifiConnected = false;
        Serial.println();
        Serial.print("ОШИБКА: Не удалось подключиться к WiFi! Статус: ");
        Serial.println(WiFi.status());
    }
}

bool wifi_manager_is_connected(void) {
    wifiConnected = (WiFi.status() == WL_CONNECTED);
    return wifiConnected;
}

const char* wifi_manager_get_ip(void) {
    if (wifi_manager_is_connected()) {
        IPAddress ip = WiFi.localIP();
        snprintf(ipAddress, sizeof(ipAddress), "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
        return ipAddress;
    }
    return "";
}
