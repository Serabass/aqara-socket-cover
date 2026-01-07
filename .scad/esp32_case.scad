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
esp32_case_outer_w = OUTER_WIDTH; // Ширина коробки (константа)
esp32_case_inner_w = esp32_case_outer_w - wall_thickness * 2; // Внутренняя ширина вычисляется из внешней

// ===== ВНУТРЕННИЕ РАЗМЕРЫ КОРПУСА =====
esp32_case_inner_l = esp32_w + clearance * 2; // Длина = ширина ESP32 + зазоры
esp32_case_inner_h = esp32_h + clearance; // Высота с запасом

// ===== ВНЕШНИЕ РАЗМЕРЫ (продолжение) =====
esp32_case_outer_l = esp32_case_inner_l + wall_thickness * 2; // Внешняя длина
esp32_case_outer_h = esp32_case_inner_h + bottom_thickness; // Внешняя высота

// ===== ПАРАМЕТРЫ ВИНТОВ =====
screw_hole_d = 2.5; // Диаметр отверстий под винты
screw_boss_h = 6; // Высота бобышек под винты
screw_boss_d = 6; // Диаметр бобышек под винты
screw_offset = wall_thickness + 3; // Отступ винтов от края (стенка + небольшой зазор)

// ===== ПАРАМЕТРЫ ВЕНТИЛЯЦИИ =====
vent_hole_d = 3; // Диаметр вентиляционных отверстий
vent_spacing = 6; // Расстояние между центрами отверстий
vent_margin = wall_thickness + 2; // Отступ вентиляции от края

// ===== МОДУЛЬ ВЕНТИЛЯЦИИ =====
module ventilation_grid(width, length, height, hole_d, spacing, margin) {
  // Вычисляем количество отверстий по каждой оси
  available_w = width - margin * 2;
  available_l = length - margin * 2;
  holes_w = floor(available_w / spacing);
  holes_l = floor(available_l / spacing);
  
  // Центрируем сетку
  start_w = margin + (available_w - (holes_w - 1) * spacing) / 2;
  start_l = margin + (available_l - (holes_l - 1) * spacing) / 2;
  
  for (i = [0 : holes_w - 1]) {
    for (j = [0 : holes_l - 1]) {
      translate([start_w + i * spacing, start_l + j * spacing, 0])
        cylinder(h=height + 1, d=hole_d, center=true);
    }
  }
}

// ===== ОСНОВНОЙ КОРПУС ESP32 =====
module esp32_case() {
  // Позиции винтов (используются в вентиляции и бобышках)
  screw_positions = [
    [screw_offset, screw_offset],
    [esp32_case_outer_w - screw_offset, screw_offset],
    [screw_offset, esp32_case_outer_l - screw_offset],
    [esp32_case_outer_w - screw_offset, esp32_case_outer_l - screw_offset],
  ];
  
  difference() {
    // Внешний корпус
    cube([esp32_case_outer_w, esp32_case_outer_l, esp32_case_outer_h]);
    
    // Внутренняя полость
    translate([wall_thickness, wall_thickness, bottom_thickness])
      cube([esp32_case_inner_w, esp32_case_inner_l, esp32_case_inner_h + 1]);
    
    // Отверстие для USB разъема ESP32 (сбоку, слева)
    translate([0, esp32_case_outer_l / 2, esp32_case_outer_h / 2])
      rotate([0, 90, 0])
        cube([esp32_usb_h, esp32_usb_w, wall_thickness * 3], center=true);
    
    // Вентиляционные отверстия на задней стороне (дно коробки, z = 0)
    translate([0, 0, 0]) {
      available_w = esp32_case_outer_w - vent_margin * 2;
      available_l = esp32_case_outer_l - vent_margin * 2;
      holes_w = floor(available_w / vent_spacing);
      holes_l = floor(available_l / vent_spacing);
      
      start_w = vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
      start_l = vent_margin + (available_l - (holes_l - 1) * vent_spacing) / 2;
      
      for (i = [0 : holes_w - 1]) {
        for (j = [0 : holes_l - 1]) {
          x = start_w + i * vent_spacing;
          y = start_l + j * vent_spacing;
          
          // Пропускаем отверстия в области бобышек для винтов
          skip_hole = false;
          for (pos = screw_positions) {
            dist = sqrt(pow(x - pos[0], 2) + pow(y - pos[1], 2));
            if (dist < screw_boss_d / 2 + vent_hole_d / 2) {
              skip_hole = true;
            }
          }
          
          if (!skip_hole) {
            translate([x, y, -0.5])
              cylinder(h=bottom_thickness + 1, d=vent_hole_d);
          }
        }
      }
    }
    
    // Вентиляционные отверстия справа (по оси Y, где y = outer_l)
    translate([0, esp32_case_outer_l, 0]) {
      available_w = esp32_case_outer_w - vent_margin * 2;
      available_h = esp32_case_outer_h - vent_margin * 2;
      holes_w = floor(available_w / vent_spacing);
      holes_h = floor(available_h / vent_spacing);
      
      start_w = vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
      start_h = vent_margin + (available_h - (holes_h - 1) * vent_spacing) / 2;
      
      for (i = [0 : holes_w - 1]) {
        for (j = [0 : holes_h - 1]) {
          translate([start_w + i * vent_spacing, 0, start_h + j * vent_spacing])
            rotate([90, 0, 0])
              cylinder(h=wall_thickness * 3, d=vent_hole_d, center=true);
        }
      }
    }
  }
  
  // Бобышки с отверстиями для винтов (4 штуки по углам)

  for (pos = screw_positions) {
    translate([pos[0], pos[1], 0]) {
      union() {
        cylinder(h=screw_boss_h, d=screw_boss_d);
        translate([0, 0, -0.5])
          cylinder(h=screw_boss_h + 5, d=screw_hole_d);
      }
    }
  }
}

// ===== ПАРАМЕТРЫ КРЫШКИ =====
oled_display_margin = 2; // Отступ вокруг видимой области OLED

// ===== КРЫШКА ДЛЯ ESP32 КОРПУСА С ЭКРАНОМ =====
module esp32_case_lid() {
  difference() {
    cube([esp32_case_outer_w, esp32_case_outer_l, top_thickness]);
    
    // Отверстие для OLED дисплея (центрированное)
    oled_x = esp32_case_outer_w / 2 - oled_display_w / 2 - oled_display_margin;
    oled_y = esp32_case_outer_l / 2 - oled_display_l / 2 - oled_display_margin;
    oled_w = oled_display_w + oled_display_margin * 2;
    oled_l = oled_display_l + oled_display_margin * 2;
    
    translate([oled_x, oled_y, -0.5])
      cube([oled_w, oled_l, top_thickness + 1]);
    
    // Вентиляционные отверстия в крышке (сетка, исключая область OLED)
    translate([0, 0, -0.5]) {
      available_w = esp32_case_outer_w - vent_margin * 2;
      available_l = esp32_case_outer_l - vent_margin * 2;
      holes_w = floor(available_w / vent_spacing);
      holes_l = floor(available_l / vent_spacing);
      
      start_w = vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
      start_l = vent_margin + (available_l - (holes_l - 1) * vent_spacing) / 2;
      
      for (i = [0 : holes_w - 1]) {
        for (j = [0 : holes_l - 1]) {
          x = start_w + i * vent_spacing;
          y = start_l + j * vent_spacing;
          
          // Пропускаем отверстия в области OLED
          if (!(x >= oled_x && x <= oled_x + oled_w && 
                y >= oled_y && y <= oled_y + oled_l)) {
            translate([x, y, 0])
              cylinder(h=top_thickness + 1, d=vent_hole_d);
          }
        }
      }
    }
    
    // Отверстия для винтов (совпадают с бобышками в корпусе)
    screw_positions = [
      [screw_offset, screw_offset],
      [esp32_case_outer_w - screw_offset, screw_offset],
      [screw_offset, esp32_case_outer_l - screw_offset],
      [esp32_case_outer_w - screw_offset, esp32_case_outer_l - screw_offset],
    ];
    
    for (pos = screw_positions) {
      translate([pos[0], pos[1], -0.5])
        cylinder(h=top_thickness + 1, d=screw_hole_d);
    }
  }
}
