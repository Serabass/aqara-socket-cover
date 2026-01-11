include <constants.scad>;

// ===== ОБОД AQARA =====
module aqara_rim() {
  difference() {
    difference() {
      union() {
        // Основное кольцо обода
        cylinder(h=GLOBAL_HEIGHT, d=AQARA_RIM_OUTER_D, center=true);

        translate([0, -AQARA_RIM_OUTER_D / 4, 0])
          cube([AQARA_RIM_OUTER_D, AQARA_RIM_OUTER_D / 2, GLOBAL_HEIGHT], center=true);
      }

      // Внутреннее отверстие (надевается на розетку)
      cylinder(h=GLOBAL_HEIGHT + 10, d=AQARA_RIM_INNER_D, center=true);
    }

    translate([0, AQARA_RIM_OUTER_D / 2 - AQARA_RIM_THICKNESS / 2, 0])
      rotate([90, 90, 0])
        aqara_button_hole();
  }
}

// ===== ОТВЕРСТИЕ ДЛЯ КНОПКИ AQARA =====
module aqara_button_hole() {
  cylinder(h=GLOBAL_HEIGHT, d=AQARA_BUTTON_DIAMETER + AQARA_BUTTON_CLEARANCE, center=true);
  rotate([0, 90, 0])
    rotate([0, 0, 90])
      rounded_cutout(AQARA_BUTTON_DIAMETER, AQARA_RIM_THICKNESS, GLOBAL_HEIGHT);
}

// ===== ЗАКРУГЛЕНИЕ =====
module rounded_cutout(width, thickness, height) {
  difference() {
    cube([width, thickness + 1, height + 2], center=true);

    // Закругления по краям
    translate([width / 2, 0, 0])
      cylinder(h=height + 2, d=thickness * 2, center=true);

    translate([-width / 2, 0, 0])
      cylinder(h=height + 2, d=thickness * 2, center=true);
  }
}
