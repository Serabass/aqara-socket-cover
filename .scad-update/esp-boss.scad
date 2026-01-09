// бобышка
include <constants.scad>;

module esp_boss(cube_base = false) {
  color("blue")
    union() {
      //if (cube_base)
      //  translate([0, 0, BOSS_BASE_HEIGHT / 2])
      //    cube([BOSS_BASE_DIAMETER, BOSS_BASE_DIAMETER, BOSS_BASE_HEIGHT], center=true);
      //else
      //  cylinder(h=BOSS_BASE_HEIGHT, d=BOSS_BASE_DIAMETER);
      cylinder(h=BOSS_HEIGHT, d=ESP32_BOSS_DIAMETER);
    }
}
