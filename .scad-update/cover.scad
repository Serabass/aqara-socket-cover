include <constants.scad>;

use <aqara-rim.scad>;

aqara_rim();
//difference() {
//  cube([ESP32_LENGTH, AQARA_RIM_OUTER_D, GLOBAL_HEIGHT], center=true);
//  translate([0, 0, -GLOBAL_HEIGHT / 2])
//    cube([ESP32_LENGTH, ESP32_WIDTH, GLOBAL_HEIGHT], center=true);
//}
