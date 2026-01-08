include <constants.scad>;
use <esp-boss.scad>;

module esp_case() {
  // Бобышки для крышки в верхней части
  lid_boss_positions = [
    [-AQARA_RIM_OUTER_D / 2 + ESP_LID_BOSS_CLEARANCE, -(ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 + ESP_LID_BOSS_CLEARANCE],
    [AQARA_RIM_OUTER_D / 2 - ESP_LID_BOSS_CLEARANCE, -(ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 + ESP_LID_BOSS_CLEARANCE],
    [-AQARA_RIM_OUTER_D / 2 + ESP_LID_BOSS_CLEARANCE, (ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 - ESP_LID_BOSS_CLEARANCE],
    [AQARA_RIM_OUTER_D / 2 - ESP_LID_BOSS_CLEARANCE, (ESP32_WIDTH + ESP32_WALL_THICKNESS * 2) / 2 - ESP_LID_BOSS_CLEARANCE],
  ];

  difference() {
    difference() {
      difference() {
        cube([AQARA_RIM_OUTER_D, ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, GLOBAL_HEIGHT], center=true);
        translate([0, 0, 1])
          cube([ESP32_LENGTH + ESP32_CLEARANCE * 2, ESP32_WIDTH + ESP32_CLEARANCE * 2, GLOBAL_HEIGHT], center=true);
      }
      if (ESP32_USB_HOLE_DIRECTION == "left" || ESP32_USB_HOLE_DIRECTION == "both")
      // USB отверстие слева
      translate([-ESP32_WIDTH, 0, 1])
        cube([ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, ESP32_USB_HOLE_WIDTH, GLOBAL_HEIGHT], center=true);

      if (ESP32_USB_HOLE_DIRECTION == "right" || ESP32_USB_HOLE_DIRECTION == "both")
        translate([ESP32_WIDTH, 0, 1])
          cube([ESP32_WIDTH + ESP32_WALL_THICKNESS * 2, ESP32_USB_HOLE_WIDTH, GLOBAL_HEIGHT], center=true);

      // Ventilation holes in the bottom
      //ventilation_holes();
    }

    if (ESP_LID_MOUNT_TYPE == "magnet")
      color("blue")for (pos = lid_boss_positions)
        translate([pos[0], pos[1], GLOBAL_HEIGHT / 2])
          lid_boss();
  }

  boss_positions = [
    [-ESP32_LENGTH / 2 + ESP32_BOSS_CLEARANCE, -ESP32_WIDTH / 2 + ESP32_BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - ESP32_BOSS_CLEARANCE, -ESP32_WIDTH / 2 + ESP32_BOSS_CLEARANCE],
    [-ESP32_LENGTH / 2 + ESP32_BOSS_CLEARANCE, ESP32_WIDTH / 2 - ESP32_BOSS_CLEARANCE],
    [ESP32_LENGTH / 2 - ESP32_BOSS_CLEARANCE, ESP32_WIDTH / 2 - ESP32_BOSS_CLEARANCE],
  ];

  for (pos = boss_positions)
    translate([pos[0], pos[1], -GLOBAL_HEIGHT / 2])
      esp_boss(cube_base=true);

  if (ESP_LID_MOUNT_TYPE == "boss")
    color("red")for (pos = lid_boss_positions)
      translate([pos[0], pos[1], GLOBAL_HEIGHT / 2])
        lid_boss();
}

module lid_boss() {
  if (ESP_LID_MOUNT_TYPE == "boss") {
    translate([0, 0, -ESP_LID_BOSS_HEIGHT / 2])
      cylinder(h=ESP_LID_BOSS_HEIGHT, d=ESP_LID_BOSS_DIAMETER);
  } else if (ESP_LID_MOUNT_TYPE == "magnet") {
    translate([0, 0, -MAGNET_HEIGHT / 2])
      cylinder(h=MAGNET_HEIGHT, d=MAGNET_DIAMETER);
  }
}

module ventilation_holes(
  width = AQARA_RIM_OUTER_D - ESP32_WALL_THICKNESS * 4,
  depth = ESP32_WIDTH + ESP32_WALL_THICKNESS * 2,
  height = GLOBAL_HEIGHT,
  hole_diameter = 3,
  spacing = 6
) {
  rows = floor(depth / spacing);
  cols = floor(width / spacing);

  for (row = [-(rows - 1) / 2:(rows - 1) / 2])
    for (col = [-(cols - 1) / 2:(cols - 1) / 2])
      translate([col * spacing, row * spacing, -height / 2 - 1])
        cylinder(h=height + 2, d=hole_diameter, center=true);
}
