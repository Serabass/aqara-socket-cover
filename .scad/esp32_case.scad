// Корпус для ESP32 DevKit V1
// Размеры компонентов:
// ESP32 DevKit V1: 25.4mm x 53.3mm x 13mm (с USB разъемом)

$fn = 64; // Качество окружностей

// ===== РАЗМЕРЫ КОМПОНЕНТОВ =====
esp32_w = 25.4; // Ширина ESP32
esp32_l = 53.3; // Длина ESP32
esp32_h = 15; // Высота ESP32 (с компонентами)
esp32_usb_w = 12; // Ширина USB разъема
esp32_usb_h = 5; // Высота USB разъема

// ===== ПАРАМЕТРЫ КОРПУСА =====
wall_thickness = 2; // Толщина стенок
bottom_thickness = 2; // Толщина дна
top_thickness = 2; // Толщина крышки
clearance = 1.5; // Зазор между компонентами и стенками

// ===== ВНУТРЕННИЕ РАЗМЕРЫ КОРПУСА =====
inner_w = esp32_l + clearance * 2; // Ширина = длина ESP32
inner_l = esp32_w + clearance * 2; // Длина = ширина ESP32
inner_h = esp32_h + clearance; // Высота с запасом

// ===== ВНЕШНИЕ РАЗМЕРЫ =====
outer_w = inner_w + wall_thickness * 2;
outer_l = inner_l + wall_thickness * 2;
outer_h = inner_h + bottom_thickness;

// ===== ПАРАМЕТРЫ ВИНТОВ =====
screw_hole_d = 2.5; // Диаметр отверстий под винты
screw_boss_h = 6; // Высота бобышек под винты
screw_boss_d = 6; // Диаметр бобышек под винты

// ===== ОСНОВНОЙ КОРПУС ESP32 =====
module esp32_case() {
  difference() {
    // Внешний корпус
    cube([outer_w, outer_l, outer_h]);
    
    // Внутренняя полость
    translate([wall_thickness, wall_thickness, bottom_thickness])
      cube([inner_w, inner_l, inner_h + 1]);
    
    // Отверстие для USB разъема ESP32 (сбоку, слева)
    translate([
      0,
      outer_l / 2,
      outer_h / 2,
    ])
      rotate([0, 90, 0])
        cube([esp32_usb_h, esp32_usb_w, wall_thickness * 3], center=true);
    
    // Вентиляционные отверстия (сверху)
    for (i = [1:5]) {
      for (j = [1:3]) {
        translate([
          wall_thickness + i * (inner_w / 6),
          wall_thickness + j * (inner_l / 4),
          outer_h - 1
        ])
          cylinder(h=3, d=2, center=true);
      }
    }
  }
  
  // Бобышки с отверстиями для винтов (4 штуки по углам)
  screw_positions = [
    [5, 5],
    [outer_w - 5, 5],
    [5, outer_l - 5],
    [outer_w - 5, outer_l - 5],
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

// ===== КРЫШКА ДЛЯ ESP32 КОРПУСА =====
module esp32_case_lid() {
  difference() {
    cube([outer_w, outer_l, top_thickness]);
    
    // Отверстия для винтов
    screw_positions = [
      [5, 5],
      [outer_w - 5, 5],
      [5, outer_l - 5],
      [outer_w - 5, outer_l - 5],
    ];
    
    for (pos = screw_positions) {
      translate([pos[0], pos[1], -0.5])
        cylinder(h=top_thickness + 1, d=screw_hole_d);
    }
  }
}

// ===== СБОРКА =====
// Раскомментируй для визуализации:
// esp32_case();
// translate([0, 0, outer_h + 1])
//   esp32_case_lid();
