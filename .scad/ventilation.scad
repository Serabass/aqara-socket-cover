include <constants.scad>;

// ===== ВЕНТИЛЯЦИОННЫЕ ОТВЕРСТИЯ =====
module ventilation_holes(
  width = AQARA_RIM_OUTER_D - ESP32_WALL_THICKNESS * 4,
  depth = ESP32_WIDTH + ESP32_WALL_THICKNESS,
  height = GLOBAL_HEIGHT,
  hole_diameter = 3,
  spacing = 5
) {
  rows = floor(depth / spacing);
  cols = floor(width / spacing);

  for (row = [-(rows - 1) / 2:(rows - 1) / 2])
    for (col = [-(cols - 1) / 2:(cols - 1) / 2])
      translate([col * spacing, row * spacing, -height / 2 - 1])
        cylinder(h=height + 2, d=hole_diameter, center=true);
}

// ===== ВЕНТИЛЯЦИОННЫЕ ПРОМЕЖУТКИ =====
module ventilation_gaps(
  width = AQARA_RIM_OUTER_D - ESP32_WALL_THICKNESS * 4,
  depth = ESP32_WIDTH + ESP32_WALL_THICKNESS * 3,
  height = GLOBAL_HEIGHT,
  hole_width = 3,
  spacing = 5
) {
  rows = floor(depth / spacing);
  cols = floor(width / spacing);

  for (col = [-(cols - 1) / 2:(cols - 1) / 2])
    translate([col * spacing, 1, -height / 2 - 1])
      cube([hole_width, spacing, height / 2], center=true);
}
