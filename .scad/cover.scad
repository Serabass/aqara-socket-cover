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
oled_display_l = 25; // Длина видимой области

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
include <esp32_case.scad>;
include <aqara-rim.scad>;

// ===== ВСПОМОГАТЕЛЬНЫЕ МОДУЛИ =====

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

module aqara_logo() {
  linear_extrude(height=6)
    import("aqara_logo.svg", center=true);
}

// ===== СБОРКА =====
//
//// Основной корпус
//translate([0, 0, 0])
//  main_case();
//
//// Кольцо для крепления на Aqara розетку

translate([-31.3, 0, 0])
  color("white")
    aqara_rim();

difference() {
  translate([19.45, 0, 18.5 / 2])
    rotate([0, 0, 90])
      esp32_case();

  //// Логотип Aqara
  translate([20, outer_l / 2 - 3, outer_h / 2])
    rotate([90, 0, 180])
      color("white")
        aqara_logo();
}

//rotate([0, 0, 90])
//  translate([0, -20.45, 19.5])
//    color("green")
//      esp32_case_lid();
