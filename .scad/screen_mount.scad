// Крепление для OLED экрана
// Использует константы из constants.scad

include <constants.scad>

// ===== СКРУГЛЕННЫЙ ПАРАЛЛЕЛЕПИПЕД =====
module rounded_box(w, l, h, r) {
  hull() {
    for (x = [r, w - r]) {
      for (y = [r, l - r]) {
        translate([x, y, r])
          sphere(r = r);
      }
    }
    translate([0, 0, r])
      cube([w, l, h - r * 2]);
  }
}

// ===== КРЕПЛЕНИЕ ДЛЯ ЭКРАНА =====
module screen_mount(
  screen_pcb_w = OLED_WIDTH,
  screen_pcb_l = OLED_LENGTH,
  screen_pcb_h = OLED_HEIGHT,
  screen_mount_hole_d = 2.2,
  screen_mount_hole_offset = 2,
  screen_mount_thickness = 2,
  screen_mount_clearance = 0.3,
  screen_mount_boss_d = 4,
  screen_mount_boss_h = 1
) {
  // Внешние размеры крепления
  mount_w = screen_pcb_w + screen_mount_clearance * 2 + screen_mount_thickness * 2;
  mount_l = screen_pcb_l + screen_mount_clearance * 2 + screen_mount_thickness * 2;
  
  // Позиции отверстий по углам (относительно центра платы)
  hole_positions = [
    [screen_mount_hole_offset, screen_mount_hole_offset],
    [screen_pcb_w - screen_mount_hole_offset, screen_mount_hole_offset],
    [screen_mount_hole_offset, screen_pcb_l - screen_mount_hole_offset],
    [screen_pcb_w - screen_mount_hole_offset, screen_pcb_l - screen_mount_hole_offset],
  ];
  
  // Углы рамки основания (относительно центра платы)
  frame_offset = screen_mount_thickness + screen_mount_clearance;
  frame_corners = [
    [-frame_offset, -frame_offset],
    [screen_pcb_w + frame_offset, -frame_offset],
    [-frame_offset, screen_pcb_l + frame_offset],
    [screen_pcb_w + frame_offset, screen_pcb_l + frame_offset],
  ];
  
  difference() {
    // Основная рамка крепления
    translate([-frame_offset, -frame_offset, 0])
      rounded_box(mount_w, mount_l, screen_mount_thickness, 1);
    
    // Отверстие под плату экрана
    translate([0, 0, -0.5])
      cube([screen_pcb_w + screen_mount_clearance * 2, screen_pcb_l + screen_mount_clearance * 2, screen_mount_thickness + 1]);
    
    // Отверстия под винты по углам
    for (pos = hole_positions) {
      translate([pos[0], pos[1], -0.5])
        cylinder(h = screen_mount_thickness + 1, d = screen_mount_hole_d);
    }
  }
  
  // Бобышки под винты с соединением к углам основания
  for (i = [0:3]) {
    pos = hole_positions[i];
    corner = frame_corners[i];
    
    // Вектор от угла к бобышке
    dx = pos[0] - corner[0];
    dy = pos[1] - corner[1];
    
    // Размеры соединительного куба
    cube_w = abs(dx) + screen_mount_boss_d / 2;
    cube_l = abs(dy) + screen_mount_boss_d / 2;
    cube_x = (dx >= 0) ? corner[0] : corner[0] - cube_w;
    cube_y = (dy >= 0) ? corner[1] : corner[1] - cube_l;
    
    difference() {
      // Соединительный куб от угла к бобышке
      translate([cube_x, cube_y, 0])
        cube([cube_w, cube_l, screen_mount_thickness + screen_mount_boss_h]);
      
      // Отверстие под винт в бобышке
      translate([pos[0], pos[1], screen_mount_thickness])
        translate([0, 0, -5])
          cylinder(h = screen_mount_boss_h + 10, d = screen_mount_hole_d);
    }
    
    // Сама бобышка
    translate([pos[0], pos[1], screen_mount_thickness])
      difference() {
        cylinder(h = screen_mount_boss_h, d = screen_mount_boss_d);
        cylinder(h = screen_mount_boss_h + 1, d = screen_mount_hole_d);
      }
  }
}
