// Корпус для ESP32 DevKit V1
// Размеры компонентов:
// ESP32 DevKit V1: 25.4mm x 53.3mm x 13mm (с USB разъемом)

$fn = 64; // Качество окружностей

// ===== КОНСТАНТЫ КОРПУСА =====
OUTER_WIDTH = 66.5; // Ширина коробки (константа)

// ===== РАЗМЕРЫ КОМПОНЕНТОВ =====
esp32_w = 28; // Ширина ESP32
esp32_l = 50; // Длина ESP32
esp32_h = 13; // Высота ESP32 (с компонентами)
esp32_usb_w = 12; // Ширина USB разъема
esp32_usb_h = 5; // Высота USB разъема

oled_w = 25; // Ширина OLED
oled_l = 25; // Длина OLED
oled_display_w = 25; // Ширина видимой области экрана
oled_display_l = 16; // Высота видимой области экрана

// ===== ПАРАМЕТРЫ КОРПУСА =====
wall_thickness = 3; // Толщина стенок
bottom_thickness = 2; // Толщина дна
top_thickness = 2; // Толщина крышки
clearance = 1.5; // Зазор между компонентами и стенками

// ===== ВНЕШНИЕ РАЗМЕРЫ =====
outer_w = OUTER_WIDTH; // Ширина коробки (константа)
inner_w = outer_w - wall_thickness * 2; // Внутренняя ширина вычисляется из внешней

// ===== ВНУТРЕННИЕ РАЗМЕРЫ КОРПУСА =====
inner_l = esp32_w + clearance * 2; // Длина = ширина ESP32 + зазоры
inner_h = esp32_h + clearance; // Высота с запасом

// ===== ВНЕШНИЕ РАЗМЕРЫ (продолжение) =====
outer_l = inner_l + wall_thickness * 2; // Внешняя длина
outer_h = inner_h + bottom_thickness; // Внешняя высота

// ===== ПАРАМЕТРЫ ВИНТОВ =====
screw_hole_d = 2.5; // Диаметр отверстий под винты
screw_boss_h = 6; // Высота бобышек под винты
screw_boss_d = 6; // Диаметр бобышек под винты
screw_offset = wall_thickness + 3; // Отступ винтов от края (стенка + небольшой зазор)

// ===== ОСНОВНОЙ КОРПУС ESP32 =====
module esp32_case() {
  difference() {
    // Внешний корпус
    cube([outer_w, outer_l, outer_h]);
    
    // Внутренняя полость
    translate([wall_thickness, wall_thickness, bottom_thickness])
      cube([inner_w, inner_l, inner_h + 1]);
    
    // Отверстие для USB разъема ESP32 (сбоку, слева)
    translate([0, outer_l / 2, outer_h / 2])
      rotate([0, 90, 0])
        cube([esp32_usb_h, esp32_usb_w, wall_thickness * 3], center=true);
  }
  
  // Бобышки с отверстиями для винтов (4 штуки по углам)
  screw_positions = [
    [screw_offset, screw_offset],
    [outer_w - screw_offset, screw_offset],
    [screw_offset, outer_l - screw_offset],
    [outer_w - screw_offset, outer_l - screw_offset],
  ];

  for (pos = screw_positions) {
    translate([pos[0], pos[1], 0]) {
      difference() {
        cylinder(h=screw_boss_h, d=screw_boss_d);
        translate([0, 0, -0.5])
          cylinder(h=screw_boss_h + 1, d=screw_hole_d);
      }
    }
  }
}

// ===== ПАРАМЕТРЫ КРЫШКИ =====
oled_display_margin = 2; // Отступ вокруг видимой области OLED

// ===== КРЫШКА ДЛЯ ESP32 КОРПУСА С ЭКРАНОМ =====
module esp32_case_lid() {
  difference() {
    cube([outer_w, outer_l, top_thickness]);
    
    // Отверстие для OLED дисплея (центрированное)
    translate([
      outer_w / 2 - oled_display_w / 2 - oled_display_margin,
      outer_l / 2 - oled_display_l / 2 - oled_display_margin,
      -0.5,
    ])
      cube([
        oled_display_w + oled_display_margin * 2,
        oled_display_l + oled_display_margin * 2,
        top_thickness + 1
      ]);
    
    // Отверстия для винтов (совпадают с бобышками в корпусе)
    screw_positions = [
      [screw_offset, screw_offset],
      [outer_w - screw_offset, screw_offset],
      [screw_offset, outer_l - screw_offset],
      [outer_w - screw_offset, outer_l - screw_offset],
    ];
    
    for (pos = screw_positions) {
      translate([pos[0], pos[1], -0.5])
        cylinder(h=top_thickness + 1, d=screw_hole_d);
    }
  }
}
