include <constants.scad>;

use <esp-boss.scad>;

module esp_case() {
  // зазор
  CLEARANCE = 1;

  difference() {
    cube([AQARA_RIM_OUTER_D, ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, GLOBAL_HEIGHT], center=true);
    translate([0, 0, 1])
      cube([ESP32_LENGTH + CLEARANCE * 2, ESP32_WIDTH + CLEARANCE * 2, GLOBAL_HEIGHT], center=true);
  }

BOSS_CLEARANCE = 2;
  boss_positions = [
    [-ESP32_LENGTH / 2 + BOSS_CLEARANCE, -ESP32_WIDTH / 2 + BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - BOSS_CLEARANCE, -ESP32_WIDTH / 2 + BOSS_CLEARANCE],
    [-ESP32_LENGTH / 2 + BOSS_CLEARANCE, ESP32_WIDTH / 2 - BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - BOSS_CLEARANCE, ESP32_WIDTH / 2 - BOSS_CLEARANCE],
  ];

  for (pos = boss_positions)
    translate([pos[0], pos[1], -GLOBAL_HEIGHT / 2])
      esp_boss(cube_base = true);
}
