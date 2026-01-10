include <constants.scad>;

use <aqara-rim.scad>;
use <esp-case.scad>;
use <esp-boss.scad>;
use <lid.scad>;
use <fake-esp32.scad>;
use <aqara-logo.scad>;

difference() {
  union() {
    aqara_rim();

    translate([0, -AQARA_RIM_OUTER_D / 2 - (ESP32_WIDTH / 2 + ESP32_WALL_THICKNESS), 0]) {
      fake_esp32();
      esp_case();
      // Рендерим крышку
      //translate([0, 0, GLOBAL_HEIGHT])
      //  esp_lid();
    }
  }

  if (RENDER_AQARA_LOGO)
    rotate([0, 0, 90])
      rotate([90, 90, 0])
        rotate([0, 0, 90])
          translate([-20, 0, AQARA_DIAMETER / 2 + 2])
            aqara_logo();
}
