include <constants.scad>;
use <esp-boss.scad>;

module fake_esp32() {
  boss_positions = [
    [-ESP32_LENGTH / 2 + ESP32_BOSS_CLEARANCE, -ESP32_WIDTH / 2 + ESP32_BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - ESP32_BOSS_CLEARANCE, -ESP32_WIDTH / 2 + ESP32_BOSS_CLEARANCE],
    [-ESP32_LENGTH / 2 + ESP32_BOSS_CLEARANCE, ESP32_WIDTH / 2 - ESP32_BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - ESP32_BOSS_CLEARANCE, ESP32_WIDTH / 2 - ESP32_BOSS_CLEARANCE],
  ];

  color("green", alpha=0.3)
    difference() {
      cube([ESP32_LENGTH, ESP32_WIDTH, 2], center=true);
      for (pos = boss_positions)
        translate([pos[0], pos[1], -GLOBAL_HEIGHT / 2])
          esp_boss(cube_base=true);
    }
}
