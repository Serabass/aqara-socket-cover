include <constants.scad>;

use <aqara-rim.scad>;
use <esp-case.scad>;
use <esp-boss.scad>;
use <lid.scad>;
use <fake-esp32.scad>;

union() {
  //aqara_rim();

  //translate([0, -AQARA_RIM_OUTER_D + ESP32_WIDTH / 2, 0])
  esp_case();
  fake_esp32();

  // Рендерим крышку
  // translate([0, 0, GLOBAL_HEIGHT])
  //   esp_lid();
}
