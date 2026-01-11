include <constants.scad>;

// ===== КРЫШКА ДЛЯ ESP32 =====
module esp_lid() {
  screen_mount_thickness = 2; // Толщина крепления экрана
  screen_clearance = 0.3; // Зазор между платой и креплением

  // Размеры крышки (соответствуют размерам корпуса)
  lid_width = AQARA_RIM_OUTER_D;
  lid_length = ESP32_WIDTH + ESP32_WALL_THICKNESS * 2;

  // Позиции бобышек для крепления крышки (из esp-case.scad)
  lid_boss_positions = [
    [-AQARA_RIM_OUTER_D / 2 + ESP_LID_BOSS_CLEARANCE, -(ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 + ESP_LID_BOSS_CLEARANCE],
    [AQARA_RIM_OUTER_D / 2 - ESP_LID_BOSS_CLEARANCE, -(ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 + ESP_LID_BOSS_CLEARANCE],
    [-AQARA_RIM_OUTER_D / 2 + ESP_LID_BOSS_CLEARANCE, (ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 - ESP_LID_BOSS_CLEARANCE],
    [AQARA_RIM_OUTER_D / 2 - ESP_LID_BOSS_CLEARANCE, (ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 - ESP_LID_BOSS_CLEARANCE],
  ];

  // Позиции отверстий на плате OLED (относительно центра платы)
  oled_hole_positions = [
    [-OLED_WIDTH / 2 + OLED_MOUNT_HOLE_OFFSET, -OLED_LENGTH / 2 + OLED_MOUNT_HOLE_OFFSET],
    [OLED_WIDTH / 2 - OLED_MOUNT_HOLE_OFFSET, -OLED_LENGTH / 2 + OLED_MOUNT_HOLE_OFFSET],
    [-OLED_WIDTH / 2 + OLED_MOUNT_HOLE_OFFSET, OLED_LENGTH / 2 - OLED_MOUNT_HOLE_OFFSET],
    [OLED_WIDTH / 2 - OLED_MOUNT_HOLE_OFFSET, OLED_LENGTH / 2 - OLED_MOUNT_HOLE_OFFSET],
  ];

  difference() {
    difference() {
      // Основная пластина крышки
      cube([lid_width, lid_length, ESP_LID_THICKNESS], center=true);

      if (ESP_LID_MOUNT_TYPE == "boss") {
        // Отверстия для крепления к бобышкам корпуса
        for (pos = lid_boss_positions) {
          translate([pos[0], pos[1], 0])
            cylinder(h=ESP_LID_THICKNESS + 1, d=ESP_LID_BOSS_DIAMETER + 0.2, center=true);
        }
      } else if (ESP_LID_MOUNT_TYPE == "magnet") {
        // Отверстия для крепления к магнитам корпуса
        for (pos = lid_boss_positions) {
          translate([pos[0], pos[1], -1])
            cylinder(h=ESP_LID_THICKNESS + 1, d=MAGNET_DIAMETER + 0.2, center=true);
        }
      }
    }

    // Вырез для OLED экрана
    translate([0, 0, 1])
      cube([OLED_WIDTH + screen_clearance * 2, OLED_LENGTH + screen_clearance * 2, screen_mount_thickness + 1], center=true);

    one_dupont_size = 2.5; // Ширина одного провода dupont
    dupont_count = 4; // Количество проводов dupont
    dupont_width = one_dupont_size * dupont_count; // Ширина всех проводов dupont
    dupont_offset = 2; // Отступ от края экрана
    dupont_clearance = 1; // Зазор между проводами dupont

    // Вырез для 4 проводов dupont
    translate([0, OLED_LENGTH / 2 - dupont_offset, 1.5])
      cube([dupont_width + dupont_clearance, one_dupont_size + dupont_clearance, 10], center=true);
  }
}
