// Обод для крепления на Aqara розетку
// ===== ОБОД ДЛЯ КРЕПЛЕНИЯ НА AQARA РОЗЕТКУ =====
rim_thickness = 3; // Толщина обода
rim_height = outer_h; // Высота обода
rim_inner_d = aqara_diameter + 0.5; // Внутренний диаметр (с зазором для надевания)
rim_outer_d = rim_inner_d + rim_thickness * 2; // Внешний диаметр
mounting_platform_h = 4; // Высота платформы для крепления корпуса

module aqara_rim() {
  difference() {
    difference() {
      difference() {
        difference() {
          union() {
            // Основное кольцо обода
            cylinder(h=rim_height, d=rim_outer_d);

            translate([0, -rim_outer_d / 2, 0])
              cube([rim_outer_d / 2, rim_outer_d, rim_height]);
          }

          // Внутреннее отверстие (надевается на розетку)
          translate([0, 0, -2.5])
            cylinder(h=rim_height + 10, d=rim_inner_d);
        }

        translate([-35, 0, outer_h / 2])
          cube([10, 2, outer_h + 2], center=true);
      }

      // закругление на концах
      translate([-31.6, 0, outer_h / 2])
        rotate([0, 0, 90])
          cut_round_cube();
    }

    // Отверстие для кнопки Aqara
    translate([-30, 0, rim_height / 2])
      rotate([0, 90, 0])
        cylinder(h=aqara_height, d=aqara_button_diameter, center=true);
  }
}

    // Закругление на концах выреза
    translate([connector_cut_x + connector_cut_w / 2 - connector_width / 2, connector_cut_y, actual_height / 2])
      rotate([0, 0, 90])
        rounded_cutout(connector_width, rim_thickness + 1, actual_height + 2);
    
    translate([connector_cut_x - connector_cut_w / 2 + connector_width / 2, connector_cut_y, actual_height / 2])
      rotate([0, 0, 90])
        rounded_cutout(connector_width, rim_thickness + 1, actual_height + 2);

    // Отверстие для кнопки Aqara
    translate([button_offset_x, 0, actual_height / 2])
      rotate([0, 90, 0])
        cylinder(h = AQARA_HEIGHT, d = AQARA_BUTTON_DIAMETER, center = true);
  }
}

// ===== ВСПОМОГАТЕЛЬНЫЙ МОДУЛЬ ДЛЯ ЗАКРУГЛЕНИЯ =====
module rounded_cutout(width, thickness, height) {
  difference() {
    cube([width, thickness + 1, height], center = true);
    
    // Закругления по краям
    translate([width / 2, 0, 0])
      cylinder(h = height, d = thickness, center = true);
    
    translate([-width / 2, 0, 0])
      cylinder(h = height, d = thickness, center = true);
  }
}
