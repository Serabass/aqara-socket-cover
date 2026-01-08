include <constants.scad>;

use <esp-boss.scad>;

module esp_case() {
  difference() {
    difference() {
      cube([AQARA_RIM_OUTER_D, ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, GLOBAL_HEIGHT], center=true);
      translate([0, 0, 1])
        cube([ESP32_LENGTH + ESP32_CLEARANCE * 2, ESP32_WIDTH + ESP32_CLEARANCE * 2, GLOBAL_HEIGHT], center=true);
    }
    translate([-ESP32_WIDTH, 0, 1])
      cube([ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, ESP32_USB_HOLE_WIDTH, GLOBAL_HEIGHT], center=true);
  }

  boss_positions = [
    [-ESP32_LENGTH / 2 + ESP32_BOSS_CLEARANCE, -ESP32_WIDTH / 2 + ESP32_BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - ESP32_BOSS_CLEARANCE, -ESP32_WIDTH / 2 + ESP32_BOSS_CLEARANCE],
    [-ESP32_LENGTH / 2 + ESP32_BOSS_CLEARANCE, ESP32_WIDTH / 2 - ESP32_BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - ESP32_BOSS_CLEARANCE, ESP32_WIDTH / 2 - ESP32_BOSS_CLEARANCE],
  ];

  for (pos = boss_positions)
    translate([pos[0], pos[1], -GLOBAL_HEIGHT / 2])
      esp_boss(cube_base = true);
}
