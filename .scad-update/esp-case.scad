include <constants.scad>;

// зазор
CLEARANCE = 1;

module esp_case() {
  #difference() {
    cube([AQARA_RIM_OUTER_D, ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, GLOBAL_HEIGHT], center=true);
    translate([0, 0, 3])
      cube([ESP32_LENGTH + CLEARANCE * 2, ESP32_WIDTH + CLEARANCE * 2, GLOBAL_HEIGHT], center=true);
  }
}
