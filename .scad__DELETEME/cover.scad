// Главный файл сборки корпуса для ESP32 + OLED + Aqara розетка
// Все координаты вычисляются параметрически

include <constants.scad>;
use <screen_mount.scad>;
use <wedge.scad>;
include <esp32_case.scad>;
include <aqara-rim.scad>;

// ===== ВЫЧИСЛЯЕМЫЕ РАЗМЕРЫ =====
function inner_width() = ESP32_LENGTH + CLEARANCE * 2;
function inner_length() = ESP32_WIDTH + OLED_WIDTH + CLEARANCE * 3;
function inner_height() = max(ESP32_HEIGHT, OLED_HEIGHT) + CLEARANCE + 2;

function outer_width() = inner_width() + WALL_THICKNESS * 2;
function outer_length() = inner_length() + WALL_THICKNESS * 2;
function outer_height() = inner_height() + BOTTOM_THICKNESS;

// ===== ПОЗИЦИОНИРОВАНИЕ КОМПОНЕНТОВ =====
// Центр координат - центр Aqara розетки
// ESP32 корпус размещается справа от центра
// Aqara обод - слева от центра
// Используем функции из esp32_case.scad (доступны через include выше)

function aqara_rim_x() = -(outer_width() / 2 + AQARA_DIAMETER / 2 + 5);
function esp32_case_x() = outer_width() / 2 - esp32_case_inner_length() / 2;
function esp32_case_z() = outer_height() / 2;
function logo_x() = esp32_case_x() + 5;
function logo_y() = outer_length() / 2 - 3;
function logo_z() = outer_height() / 2;

// ===== МОДУЛЬ ЛОГОТИПА AQARA =====
module aqara_logo() {
  linear_extrude(height=6)
    import("aqara_logo.svg", center=true);
}

// ===== ОСНОВНОЙ КОРПУС (если нужен отдельно) =====
module main_case() {
  difference() {
    // Внешний корпус
    cube([outer_width(), outer_length(), outer_height()], center=true);

    // Внутренняя полость
    translate([0, 0, BOTTOM_THICKNESS / 2])
      cube([inner_width(), inner_length(), inner_height() + 1], center=true);
  }
}

// ===== СБОРКА =====
// Раскомментируй нужные части для рендеринга

// Aqara обод
//translate([aqara_rim_x(), 0, 0])
//  color("white")
//    aqara_rim(rim_height=outer_height());

//// ESP32 корпус с вырезом под логотип
//difference() {
// translate([esp32_case_x(), 0, esp32_case_z()])
//   rotate([0, 0, 90])
//     esp32_case();
//
//  // Логотип Aqara (вырез)
//  translate([logo_x(), logo_y(), logo_z()])
//    rotate([90, 0, 180])
//      color("white")
//        aqara_logo();
//}

// Крышка ESP32 (раскомментируй если нужно)
//rotate([0, 0, 90])
//  translate([0, -esp32_case_x(), outer_height()])
//    color("green")
//      esp32_case_lid();
esp32_case();
