use <constants.scad>;

// Aqara розетка
AQARA_DIAMETER = 60;
AQARA_BUTTON_DIAMETER = 15;
AQARA_RIM_THICKNESS = 3;

module aqara_rim() {
  rim_inner_d = AQARA_DIAMETER + 0.5; // Внутренний диаметр (с зазором для надевания)
  rim_outer_d = rim_inner_d + AQARA_RIM_THICKNESS * 2; // Внешний диаметр
  difference() {
    union() {
      // Основное кольцо обода
      cylinder(h=GLOBAL_HEIGHT, d=rim_outer_d);

      translate([0, -rim_outer_d / 2, 0])
        cube([rim_outer_d / 2, rim_outer_d, GLOBAL_HEIGHT]);
    }
  }
}
