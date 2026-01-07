// Корпус для ESP32 DevKit V1
// Размеры компонентов:
// ESP32 DevKit V1: 25.4mm x 53.3mm x 13mm (с USB разъемом)

$fn = 64; // Качество окружностей

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

// ===== ВНУТРЕННИЕ РАЗМЕРЫ КОРПУСА (БАЗОВЫЕ ЗНАЧЕНИЯ) =====
esp32_case_inner_w = 53.1; // Внутренняя ширина (базовое значение)
esp32_case_inner_l = esp32_w + clearance * 2 - 2; // Внутренняя длина = ширина ESP32 + зазоры
esp32_case_inner_h = esp32_h + clearance; // Внутренняя высота с запасом

// ===== ВНЕШНИЕ РАЗМЕРЫ (вычисляются из внутренних) =====
esp32_case_outer_w = 66.5; // Внешняя ширина
esp32_case_outer_l = esp32_case_inner_l + wall_thickness * 2; // Внешняя длина
esp32_case_outer_h = esp32_case_inner_h + bottom_thickness + top_thickness; // Внешняя высота

// ===== ПАРАМЕТРЫ ВИНТОВ =====
screw_hole_d = 3; // Диаметр отверстий под винты
screw_boss_h = 6; // Высота бобышек под винты
screw_boss_d = 6; // Диаметр бобышек под винты
screw_offset = 3; // Отступ винтов от края (стенка + небольшой зазор)

// ===== ПАРАМЕТРЫ ВЕНТИЛЯЦИИ =====
vent_hole_d = 4; // Диаметр вентиляционных отверстий
vent_spacing = 6; // Расстояние между центрами отверстий
vent_margin = wall_thickness; // Отступ вентиляции от края

// ===== ПАРАМЕТРЫ ОТВЕРСТИЙ ESP32 =====
esp32_mount_hole_d = 3; // Диаметр отверстий для крепления ESP32
esp32_mount_hole_offset = 2.5; // Отступ отверстий от края ESP32

// ===== ФЕЙКОВЫЙ ESP32 ДЛЯ ИЗМЕРЕНИЙ =====
module fake_esp32()
// Полупрозрачный ESP32 с отверстиями по углам
  %color("green", alpha=0.3) {
    difference() {
      // Основной корпус ESP32 (от центра)
      cube([esp32_w, esp32_l, 3], center=true);

      // Отверстия для крепления по углам
      half_w = esp32_w / 2;
      half_l = esp32_l / 2;
      mount_holes = [
        [-half_w + esp32_mount_hole_offset, -half_l + esp32_mount_hole_offset],
        [half_w - esp32_mount_hole_offset, -half_l + esp32_mount_hole_offset],
        [-half_w + esp32_mount_hole_offset, half_l - esp32_mount_hole_offset],
        [half_w - esp32_mount_hole_offset, half_l - esp32_mount_hole_offset],
      ];

      for (pos = mount_holes) {
        translate([pos[0], pos[1], 0])
          cylinder(h=esp32_h + 1, d=esp32_mount_hole_d, center=true);
      }
    }
  }

// ===== ОСНОВНОЙ КОРПУС ESP32 =====
module esp32_case() {
  // Позиции винтов относительно центра (используются в вентиляции и бобышках)
  half_w = esp32_case_inner_w / 2;
  half_l = esp32_case_inner_l / 2;
  screw_positions = [
    [-half_w + screw_offset, -half_l + screw_offset],
    [half_w - screw_offset, -half_l + screw_offset],
    [-half_w + screw_offset, half_l - screw_offset],
    [half_w - screw_offset, half_l - screw_offset],
  ];

  // if ($preview)
  //   translate([0, 0, -esp32_case_outer_h / 2 + bottom_thickness + esp32_h / 2])
  //     rotate([0, 0, 90])
  //       fake_esp32();

  difference() {
    // Внешний корпус (от центра)
    cube([esp32_case_outer_w, esp32_case_outer_l, esp32_case_outer_h], center=true);

    // Внутренняя полость (от центра)
    translate([0, 0, (bottom_thickness - top_thickness) / 2])
      cube([esp32_case_inner_w, esp32_case_inner_l, esp32_case_inner_h + 8], center=true);

    // Отверстие для USB разъема ESP32 (сбоку, слева)
    translate([-half_w - wall_thickness, 0, 1.8])
      rotate([0, 90, 0])
        cube([esp32_usb_h + 10, esp32_usb_w, wall_thickness * 4], center=true);

    // Вентиляционные отверстия снизу (по оси Y, по центру бокса)
    available_w = esp32_case_inner_w - vent_margin * 2;
    available_h = esp32_case_inner_h;
    holes_w = max(0, floor(available_w / vent_spacing));
    holes_h = max(0, floor(available_h / vent_spacing));

    if (holes_w > 0 && holes_h > 0) {
      half_outer_w = esp32_case_inner_w / 2;
      start_w = -half_outer_w + vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
      start_h = -esp32_case_outer_h / 2 + vent_margin + (available_h - (holes_h - 1) * vent_spacing) / 2;

      for (i = [0:holes_w - 1])
        for (j = [0:holes_h - 1])
          translate([start_w + i * vent_spacing, -esp32_case_inner_h, start_h + j * vent_spacing])
            cube([3, 10, 5], center=true);
    }

    cube([esp32_case_inner_w, esp32_case_inner_l, esp32_case_inner_h + 8], center=true);
  }

  // Бобышки с отверстиями для винтов (4 штуки по углам)
  for (pos = screw_positions)
    translate([pos[0], pos[1], -esp32_case_outer_h / 2])
      color("blue")
        union() {
          cylinder(h=screw_boss_h, d=screw_boss_d);
          cylinder(h=screw_boss_h + 8, d=screw_hole_d);
        }

  difference() {
    // Пол (дно корпуса)
    translate([0, 0, -esp32_case_outer_h / 2 + bottom_thickness / 2])
      cube([esp32_case_outer_w, esp32_case_outer_l, bottom_thickness], center=true);

    // Вентиляционные отверстия на задней стороне (дно коробки)
    half_inner_w = esp32_case_inner_w / 2;
    half_inner_l = esp32_case_inner_l / 2;
    available_w = esp32_case_inner_w - vent_margin * 2;
    available_l = esp32_case_inner_l - vent_margin * 2;
    holes_w = max(0, floor(available_w / vent_spacing));
    holes_l = max(0, floor(available_l / vent_spacing));

    if (holes_w > 0 && holes_l > 0) {
      start_w = -half_inner_w + vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
      start_l = -half_inner_l + vent_margin + (available_l - (holes_l - 1) * vent_spacing) / 2;

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
            translate([x, y, -esp32_case_inner_h / 2])
              cylinder(h=bottom_thickness + 5, d=vent_hole_d, center=true);
          }
        }
      }
    }
  }
}

// ===== ПАРАМЕТРЫ КРЫШКИ =====
oled_display_margin = 2; // Отступ вокруг видимой области OLED

// ===== ПАРАМЕТРЫ КРЕПЛЕНИЙ ЭКРАНА =====
screen_mount_d = 2.5; // Диаметр креплений для экрана
screen_mount_h = 2; // Высота креплений для экрана
screen_mount_offset = 2; // Отступ креплений от края OLED

// ===== ПАРАМЕТРЫ ОТВЕРСТИЯ ДЛЯ ПРОВОДОВ =====
dupont_hole_w = 10; // Ширина отверстия для 4 проводов dupont
dupont_hole_h = 2; // Высота отверстия для проводов
dupont_hole_offset = 1; // Отступ отверстия от края крышки

// ===== КРЫШКА ДЛЯ ESP32 КОРПУСА С ЭКРАНОМ =====
module esp32_case_lid() {
  half_w = esp32_case_outer_w / 2;
  half_l = esp32_case_outer_l / 2;

  // Позиция и размеры OLED относительно центра (используются в difference и для креплений)
  oled_w = oled_display_w + oled_display_margin * 2;
  oled_l = oled_display_l + oled_display_margin * 2;
  oled_x = -oled_w / 2;
  oled_y = -oled_l / 2;

  difference() {
    // Основная крышка (от центра)
    cube([esp32_case_outer_w, esp32_case_outer_l, top_thickness], center=true);

    // Отверстие для 4 проводов dupont (10мм)
    translate([0, oled_l / 2 - screen_mount_offset, 0])
      cube([dupont_hole_w + 2, dupont_hole_h + 1, 10], center=true);

    // Вентиляционные отверстия в крышке (сетка, исключая область OLED)
    available_w = esp32_case_outer_w - vent_margin * 2;
    available_l = esp32_case_outer_l - vent_margin * 2;
    holes_w = floor(available_w / vent_spacing);
    holes_l = floor(available_l / vent_spacing);

    start_w = -half_w + vent_margin + (available_w - (holes_w - 1) * vent_spacing) / 2;
    start_l = -half_l + vent_margin + (available_l - (holes_l - 1) * vent_spacing) / 2;

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
            cylinder(h=top_thickness + 1, d=vent_hole_d, center=true);
      }

    // Отверстия для винтов (совпадают с бобышками в корпусе)
    screw_positions = [
      // [-half_w + 1.5, -half_l + 1.5],
      // [half_w - 1.5, -half_l + 1.5],
      // [-half_w + 1.5, half_l - 1.5],
      // [half_w - 1.5, half_l - 1.5],
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
    translate([pos[0], pos[1], 0])
      cylinder(h=screen_mount_h + 1, d=screen_mount_d, center=false);
}
