include <constants.scad>;

// Крышка для ESP корпуса с креплением для OLED экрана
module esp_lid() {
  lid_thickness = 2; // Толщина крышки
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
    // Основная пластина крышки
    cube([lid_width, lid_length, lid_thickness], center=true);

    if (ESP_LID_MOUNT_TYPE == "boss") {
      // Отверстия для крепления к бобышкам корпуса
      for (pos = lid_boss_positions) {
        translate([pos[0], pos[1], 0])
          cylinder(h=lid_thickness + 1, d=ESP_LID_BOSS_DIAMETER + 0.2, center=true);
      }
    } else if (ESP_LID_MOUNT_TYPE == "magnet") {
      // Отверстия для крепления к магнитам корпуса
      for (pos = lid_boss_positions) {
        translate([pos[0], pos[1], -1])
          cylinder(h=lid_thickness + 1, d=MAGNET_DIAMETER + 0.2, center=true);
      }
    }
  }

  // Крепление для OLED экрана (по центру крышки)
  translate([0, 0, lid_thickness / 2]) {
    mount_w = OLED_WIDTH + screen_clearance * 2 + screen_mount_thickness * 2;
    mount_l = OLED_LENGTH + screen_clearance * 2 + screen_mount_thickness * 2;
    boss_height = 2;
    boss_diameter = 4;

    difference() {
      union() {
        // Внешняя рамка крепления
        cube([mount_w, mount_l, screen_mount_thickness], center=true);

        // Бобышки под винты для крепления OLED (соединены с рамкой)
        for (pos = oled_hole_positions) {
          translate([pos[0], pos[1], screen_mount_thickness / 2 + boss_height / 2]) {
            cylinder(h=boss_height, d=boss_diameter, center=true);
          }
        }
      }

      // Вырез под плату OLED
      translate([0, 0, -0.5])
        cube([OLED_WIDTH + screen_clearance * 2, OLED_LENGTH + screen_clearance * 2, screen_mount_thickness + 1], center=true);

      // Вырез для видимой области экрана
      translate([0, 0, screen_mount_thickness / 2])
        cube([OLED_DISPLAY_WIDTH, OLED_DISPLAY_LENGTH, screen_mount_thickness + boss_height + 1], center=true);

      // Отверстия под винты для крепления OLED
      for (pos = oled_hole_positions) {
        translate([pos[0], pos[1], 0])
          cylinder(h=screen_mount_thickness + boss_height + 1, d=OLED_MOUNT_HOLE_D, center=true);
      }
    }
  }
}
