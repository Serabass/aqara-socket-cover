// Корпус для ESP32 DevKit V1
// Размеры компонентов:
// ESP32 DevKit V1: 25.4mm x 53.3mm x 13mm (с USB разъемом)

$fn = 64; // Качество окружностей

// ===== КОНСТАНТЫ КОРПУСА =====
OUTER_WIDTH = 66.5; // Ширина коробки (константа)
OUTER_HEIGHT = 18.5; // Высота коробки (константа)

// ===== РАЗМЕРЫ КОМПОНЕНТОВ =====
esp32_w = 28; // Ширина ESP32
esp32_l = 50; // Длина ESP32
esp32_h = 13; // Высота ESP32 (с компонентами)
esp32_usb_w = 12; // Ширина USB разъема
esp32_usb_h = 5; // Высота USB разъема

oled_w = 25; // Ширина OLED
oled_l = 25; // Длина OLED
oled_display_w = 25; // Ширина видимой области экрана
oled_display_l = 25; // Высота видимой области экрана

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
esp32_case_outer_h = OUTER_HEIGHT; // Внешняя высота

// ===== ПАРАМЕТРЫ ВИНТОВ =====
screw_hole_d = 2.5; // Диаметр отверстий под винты
screw_boss_h = 6; // Высота бобышек под винты
screw_boss_d = 6; // Диаметр бобышек под винты
screw_offset = wall_thickness + 3; // Отступ винтов от края (стенка + небольшой зазор)

// ===== ПАРАМЕТРЫ ВЕНТИЛЯЦИИ =====
vent_hole_d = 3; // Диаметр вентиляционных отверстий
vent_spacing = 6; // Расстояние между центрами отверстий
vent_margin = wall_thickness + 3; // Отступ вентиляции от края

// ===== ОСНОВНОЙ КОРПУС ESP32 =====
module esp32_case() {
  // Смещаем весь корпус так, чтобы центр был в (0, 0, 0)
  translate([-esp32_case_outer_w / 2, -esp32_case_outer_l / 2, -esp32_case_outer_h / 2]) {
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
        cube([esp32_case_inner_w, esp32_case_inner_l, esp32_case_inner_h + 4]);

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

        for (i = [0:holes_w - 1]) {
          for (j = [0:holes_l - 1]) {
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

      // Вентиляционные отверстия снизу (по оси Y, где y = outer_l)
      translate([0, esp32_case_outer_l, 0]) {
        available_w = esp32_case_outer_w - vent_margin * 2;
        available_h = esp32_case_outer_h - vent_margin * 2;
        holes_w = floor(available_w / vent_spacing);
        holes_h = floor(available_h / vent_spacing);

        start_w = vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
        start_h = vent_margin + (available_h - (holes_h - 1) * vent_spacing) / 2;

        for (i = [0:holes_w - 1])
          for (j = [0:holes_h - 1])
            translate([start_w + i * vent_spacing, -35, start_h + j * vent_spacing])
              cube([2, 10, 10], center=true);
      }
    }

    // Бобышки с отверстиями для винтов (4 штуки по углам)
    for (pos = screw_positions)
      translate([pos[0], pos[1], 0])
        color("blue")
          union() {
            cylinder(h=screw_boss_h, d=screw_boss_d);
            cylinder(h=screw_boss_h + 8, d=screw_hole_d);
          }
  }
}

// ===== ПАРАМЕТРЫ КРЫШКИ =====
oled_display_margin = 2; // Отступ вокруг видимой области OLED

// ===== ПАРАМЕТРЫ КРЕПЛЕНИЙ ЭКРАНА =====
screen_mount_d = 3; // Диаметр креплений для экрана
screen_mount_h = 2; // Высота креплений для экрана
screen_mount_offset = 2; // Отступ креплений от края OLED

// ===== ПАРАМЕТРЫ ОТВЕРСТИЯ ДЛЯ ПРОВОДОВ =====
dupont_hole_w = 10; // Ширина отверстия для 4 проводов dupont
dupont_hole_h = 2; // Высота отверстия для проводов
dupont_hole_offset = 1; // Отступ отверстия от края крышки

// ===== КРЫШКА ДЛЯ ESP32 КОРПУСА С ЭКРАНОМ =====
module esp32_case_lid()
// Смещаем всю крышку так, чтобы центр был в (0, 0, 0)
  translate([-esp32_case_outer_w / 2, -esp32_case_outer_l / 2, -top_thickness / 2]) {
    // Позиция и размеры OLED (используются в difference и для креплений)
    oled_x = esp32_case_outer_w / 2 - oled_display_w / 2 - oled_display_margin;
    oled_y = esp32_case_outer_l / 2 - oled_display_l / 2 - oled_display_margin;
    oled_w = oled_display_w + oled_display_margin * 2;
    oled_l = oled_display_l + oled_display_margin * 2;

    difference() {
      cube([esp32_case_outer_w, esp32_case_outer_l, top_thickness]);

      // Отверстие для 4 проводов dupont (10мм)
      translate([dupont_hole_offset, esp32_case_outer_l / 2, -0.5])
        #cube([dupont_hole_w, dupont_hole_h, 10], center=true);

      // Вентиляционные отверстия в крышке (сетка, исключая область OLED)
      translate([0, 0, -0.5]) {
        available_w = esp32_case_outer_w - vent_margin * 2;
        available_l = esp32_case_outer_l - vent_margin * 2;
        holes_w = floor(available_w / vent_spacing);
        holes_l = floor(available_l / vent_spacing);

        start_w = vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
        start_l = vent_margin + (available_l - (holes_l - 1) * vent_spacing) / 2;

        for (i = [0:holes_w - 1])
          for (j = [0:holes_l - 1]) {
            x = start_w + i * vent_spacing;
            y = start_l + j * vent_spacing;

            // Пропускаем отверстия в области OLED
            if (
              !(
                x >= oled_x && x <= oled_x + oled_w && y >= oled_y && y <= oled_y + oled_l
              )
            )
              translate([x, y, 0])
                cylinder(h=top_thickness + 1, d=vent_hole_d);
          }
      }

      // Отверстия для винтов (совпадают с бобышками в корпусе)
      screw_positions = [
        [1.5, 1.5],
        [esp32_case_outer_w - 1.5, 1.5],
        [1.5, esp32_case_outer_l - 1.5],
        [esp32_case_outer_w - 1.5, esp32_case_outer_l - 1.5],
      ];

      for (pos = screw_positions)
        translate([pos[0], pos[1], 0])
          cylinder(h=top_thickness + 7, d=screw_hole_d, center=true);
    }

    // Крепления для экрана (4 бобышки по углам OLED)
    screen_mount_positions = [
      [oled_x + screen_mount_offset, oled_y + screen_mount_offset],
      [oled_x + oled_w - screen_mount_offset, oled_y + screen_mount_offset],
      [oled_x + screen_mount_offset, oled_y + oled_l - screen_mount_offset],
      [oled_x + oled_w - screen_mount_offset, oled_y + oled_l - screen_mount_offset],
    ];

    for (pos = screen_mount_positions)
      translate([pos[0], pos[1], top_thickness / 2])
        cylinder(h=screen_mount_h + 2, d=screen_mount_d, center=true);
  }
