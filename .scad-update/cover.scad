include <constants.scad>;

use <aqara-rim.scad>;
use <esp-case.scad>;
use <esp-boss.scad>;

union() {
  //aqara_rim();

  //translate([0, -AQARA_RIM_OUTER_D + ESP32_WIDTH / 2, 0])
  esp_case();
  //esp_boss(cube_base = true);
}
