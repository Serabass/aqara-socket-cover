include <constants.scad>;

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
      translate([0, 0, -2.5])
        cylinder(h=GLOBAL_HEIGHT + 10, d=AQARA_RIM_INNER_D, center=true);
    }
    
    translate([0, AQARA_RIM_OUTER_D / 2, 0])
      rotate([90, 90, 0])
        aqara_button_hole();
  }
}

module aqara_button_hole() {
  difference() {
    union() {
      cylinder(h=GLOBAL_HEIGHT, d=AQARA_BUTTON_DIAMETER, center=true);
    }
  }
}
