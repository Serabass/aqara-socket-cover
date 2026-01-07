// Корпус для ESP32 DevKit V1 + OLED SSD1306 + Aqara накладная розетка
// Размеры компонентов:
// ESP32 DevKit V1: 25.4mm x 53.3mm x 13mm (с USB разъемом)
// OLED SSD1306: 27mm x 27mm x 4mm (модуль)
// Aqara накладная розетка: ~85mm диаметр, ~20mm высота

$fn = 64; // Качество окружностей

// ===== РАЗМЕРЫ КОМПОНЕНТОВ =====
esp32_w = 25.4; // Ширина ESP32
esp32_l = 53.3; // Длина ESP32
esp32_h = 13; // Высота ESP32 (с компонентами)
esp32_usb_w = 12; // Ширина USB разъема
esp32_usb_h = 5; // Высота USB разъема

oled_w = 25; // Ширина OLED
oled_l = 25; // Длина OLED
oled_h = 1.6; // Высота OLED
oled_display_w = 25; // Ширина видимой области (с зазором)
oled_display_l = 16; // Длина видимой области

// ===== ПАРАМЕТРЫ КОРПУСА =====
wall_thickness = 2; // Толщина стенок
bottom_thickness = 2; // Толщина дна
top_thickness = 2; // Толщина крышки
clearance = 1.5; // Зазор между компонентами и стенками

// ===== РАЗМЕРЫ AQARA РОЗЕТКИ =====
aqara_diameter = 60; // Диаметр накладной розетки
aqara_height = 20; // Высота части, которая накладывается
aqara_inner_d = 75; // Внутренний диаметр (для крепления)

aqara_button_diameter = 15; // Диаметр кнопки

// ===== ВНУТРЕННИЕ РАЗМЕРЫ КОРПУСА =====
// ESP32 размещаем вдоль, OLED рядом
inner_w = esp32_l + clearance * 2; // Ширина = длина ESP32
inner_l = esp32_w + oled_w + clearance * 3; // Длина = ширина ESP32 + OLED + зазоры
inner_h = max(esp32_h, oled_h) + clearance + 2; // Высота с запасом

// ===== ВНЕШНИЕ РАЗМЕРЫ =====
outer_w = inner_w + wall_thickness * 2;
outer_l = inner_l + wall_thickness * 2;
outer_h = inner_h + bottom_thickness;

// ===== ПАРАМЕТРЫ ВИНТОВ =====
screw_hole_d = 2.5; // Диаметр отверстий под винты
screw_boss_h = outer_h; // Высота бобышек под винты
screw_boss_d = 6; // Диаметр бобышек под винты

use <screen_mount.scad>;
use <wedge.scad>;
use <esp32_case.scad>;

// ===== ВСПОМОГАТЕЛЬНЫЕ МОДУЛИ =====

// Клин (половина куба по диагонали) - "трамплин"
// w - ширина, l - длина, h - высота
// direction - направление скоса: "x" (по оси X), "y" (по оси Y), или "xy" (по обеим)
// Альтернативный простой способ через linear_extrude:
// module wedge_simple(w, l, h) {
//   linear_extrude(height=h, scale=[1, 0]) {
//     square([w, l]);
//   }
// }
module screw_hole() {
  difference() {
    union() {
      // cylinder(h=screw_boss_h, d=screw_boss_d);

      translate([-3.3, -3.3, 0])
        rotate([270, -90, 0])
          wedge(screw_boss_h, 12, 12, "x");
    }
    translate([0, 0, -0.5])
      cylinder(h=screw_boss_h + 1, d=screw_hole_d);
  }
}

// ===== ОСНОВНОЙ КОРПУС =====
module main_case() {
  difference() {
    // Внешний корпус
    rounded_box(outer_w, outer_l, outer_h, 0);

    // Внутренняя полость
    translate([wall_thickness, wall_thickness, bottom_thickness])
      cube([inner_w, inner_l, inner_h + 1]);

    // Отверстие для USB разъема ESP32
    translate(
      [
        outer_w / 2,
        outer_l,
        outer_h / 2,
      ]
    )
      rotate([90, 90, 0])
        cube([esp32_usb_h, esp32_usb_w, bottom_thickness * 3], center=true);

    //// Отверстия для проводов I2C (OLED)
    //translate([
    //    wall_thickness + esp32_l + clearance, 
    //    wall_thickness + esp32_w + clearance + oled_w/2 - 1, 
    //    0
    //])
    //    cube([5, 2, bottom_thickness + 1]);

    // Вентиляционные отверстия (опционально)
    translate([-14, 0, 0])for (i = [1:9]) {
      for (j = [1:19]) {
        translate([outer_w / 2 + i * (inner_w / 20), wall_thickness + j * (inner_l / 20), 1])
          cylinder(h=3, d=1.5, center=true);
      }
    }

    // Вентиляционные отверстия (опционально)
    translate([12, 0, 2])for (i = [1:5]) {
      rotate([90, 0, 90])for (j = [1:10]) {
        translate([0, i * (inner_w / 20), j * (inner_l / 20)])
          rotate([0, 90, 0])
            // cube([10, inner_l / 30, 1.5], center=true);
            cylinder(h=5.5, d=1.5, center=true);
      }
    }

    // Вентиляционные отверстия (опционально)
    translate([60, 58, 1])for (i = [1:5]) {
      rotate([90, 0, 0])for (j = [1:2]) {
        translate([0, i * (inner_w / 20), j * (inner_l / 20)])
          rotate([0, 90, 0])
            // cube([10, inner_l / 30, 1.5], center=true);
            cylinder(h=5.5, d=1.5, center=true);
      }
    }

    // Вентиляционные отверстия (опционально)
    translate([60, 23, 1])for (i = [1:5]) {
      rotate([90, 0, 0])for (j = [1:2]) {
        translate([0, i * (inner_w / 20), j * (inner_l / 20)])
          rotate([0, 90, 0])
            // cube([10, inner_l / 30, 1.5], center=true);
            cylinder(h=5.5, d=1.5, center=true);
      }
    }
  }

  // Бобышки с отверстиями для винтов (4 штуки по углам на верхней части)
  screw_positions = [
    [5, 5],
    [outer_w - 5, 5],
    [5, outer_l - 5],
    [outer_w - 5, outer_l - 5],
  ];

  for (i = [0:3]) {
    translate([screw_positions[i][0], screw_positions[i][1], 0]) {
      if (i == 0) {
        rotate([0, 0, 0])
          screw_hole();
      } else if (i == 1) {
        rotate([0, 0, 90])
          screw_hole();
      } else if (i == 2) {
        rotate([0, 0, 270])
          screw_hole();
      } else if (i == 3) {
        rotate([0, 0, 180])
          screw_hole();
      }
    }
  }
}

module screw_fill_rotate(i) {
  if (i == 0) {
    translate([0, 110, 0])
      rotate([0, 0, 0])
        children(0);
  } else if (i == 1) {
    rotate([0, 0, 0])
      children(0);
  } else if (i == 2) {
    rotate([0, 0, 0])
      children(0);
  } else if (i == 3) {
    rotate([0, 0, 0])
      children(0);
  } else {
    children(0);
  }
}

// ===== КРЫШКА С ОТВЕРСТИЕМ ДЛЯ OLED =====
module lid() {
  difference() {
    rounded_box(outer_w, outer_l, top_thickness, 3);

    // Отверстие для OLED дисплея (с запасом)
    translate(
      [
        outer_w / 2 - oled_display_l / 2 - 2,
        outer_l - wall_thickness - oled_w - clearance - 2,
        -0.5,
      ]
    )
      rounded_box(oled_display_l + 4, oled_display_w + 4, top_thickness + 1, 1);
  }
}

// ===== АДАПТЕР ДЛЯ AQARA РОЗЕТКИ =====
module aqara_adapter() {
  difference() {
    // Внешнее кольцо
    cylinder(h=aqara_height, d=aqara_diameter);

    // Внутреннее отверстие
    translate([0, 0, -0.5])
      cylinder(h=aqara_height + 1, d=aqara_inner_d);

    // Крепление к основному корпусу (вырез под корпус)
    translate([0, 0, aqara_height - 5])
      cube([outer_w + 1, outer_l + 1, 6], center=true);
  }

  // Платформа для крепления корпуса
  translate([0, 0, aqara_height])
    difference() {
      rounded_box(outer_w + 4, outer_l + 4, 3, 2);
      translate([0, 0, -0.5])
        cube([outer_w, outer_l, 4], center=true);
    }
}

module cut_round_cube() {
  width = 6;
  difference() {
    cube([width, rim_thickness + 1, outer_h + 2], center=true);
    translate([width / 2, 0, 0])
      rotate([0, 0, 0])
        cylinder(h=outer_h + 2, d=rim_thickness, center=true);
    translate([-width / 2, 0, 0])
      rotate([0, 0, 0])
        cylinder(h=outer_h + 2, d=rim_thickness, center=true);
  }
}

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
          // Основное кольцо обода
          cylinder(h=rim_height, d=rim_outer_d);

          // Внутреннее отверстие (надевается на розетку)
          translate([0, 0, -0.5])
            cylinder(h=rim_height + 1, d=rim_inner_d);
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

  // // Платформа для крепления основного корпуса
  // translate([0, 0, rim_height])
  //     difference() {
  //         // Основание платформы
  //         rounded_box(outer_w + 6, outer_l + 6, mounting_platform_h, 2);
  //         
  //         // Отверстие под корпус (с зазором)
  //         translate([0, 0, -0.5])
  //             cube([outer_w + 1, outer_l + 1, mounting_platform_h + 1], center = true);
  //     }
  // 
  // Усиливающие ребра (4 штуки по углам)
  //for (angle = [0, 90, 180, 270]) {
  //    rotate([0, 0, angle])
  //        translate([rim_outer_d/2 - rim_thickness/2, 0, 0])
  //            cube([rim_thickness, outer_w/2 + 5, rim_height], center = true);
  //}
}

module aqara_logo() {
  linear_extrude(height=2)
    import("aqara_logo.svg", center=true);
}

// ===== СБОРКА =====
//
//// Основной корпус
//translate([0, 0, 0])
//  main_case();
//
//// Кольцо для крепления на Aqara розетку
translate([-31.3, outer_l / 2, 0])
  aqara_rim();

//// Логотип Aqara
//translate([59, outer_l / 2, outer_h / 2])
//  rotate([90, 0, 90])
//    aqara_logo();
//
// Крепление для экрана (отдельно для печати)
// Раскомментируй для визуализации:
// translate([0, 0, 0])
//   screen_mount();

translate([34, 0, 0])
  rotate([0, 0, 90])
    esp32_case();
