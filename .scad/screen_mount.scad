
// Скругленный параллелепипед
module rounded_box(w, l, h, r) {
  hull() {
    for (x = [r, w - r]) {
      for (y = [r, l - r]) {
        translate([x, y, r])
          sphere(r=r);
      }
    }
    translate([0, 0, r])
      cube([w, l, h - r * 2]);
  }
}

// ===== КРЕПЛЕНИЕ ДЛЯ ЭКРАНА =====
module screen_mount() {
  // ===== ПАРАМЕТРЫ КРЕПЛЕНИЯ ЭКРАНА =====
  screen_pcb_w = 25; // Ширина платы экрана
  screen_pcb_l = 25; // Длина платы экрана
  screen_pcb_h = 1.6; // Толщина платы экрана
  screen_mount_hole_d = 2.2; // Диаметр отверстий под винты M2 (2.2 для свободного прохода)
  screen_mount_hole_offset = 2; // Отступ отверстий от края платы
  screen_mount_thickness = 2; // Толщина крепления
  screen_mount_clearance = 0.3; // Зазор между платой и креплением
  screen_mount_boss_d = 4; // Диаметр бобышек под винты
  screen_mount_boss_h = 1; // Высота бобышек

  // Внешние размеры крепления (с запасом)
  mount_w = screen_pcb_w + screen_mount_clearance * 2 + screen_mount_thickness * 2;
  mount_l = screen_pcb_l + screen_mount_clearance * 2 + screen_mount_thickness * 2;
  
  // Позиции отверстий по углам
  hole_positions = [
    [screen_mount_hole_offset, screen_mount_hole_offset],
    [screen_pcb_w - screen_mount_hole_offset, screen_mount_hole_offset],
    [screen_mount_hole_offset, screen_pcb_l - screen_mount_hole_offset],
    [screen_pcb_w - screen_mount_hole_offset, screen_pcb_l - screen_mount_hole_offset],
  ];
  
  difference() {
    // Основная рамка крепления
    translate([-screen_mount_thickness - screen_mount_clearance, -screen_mount_thickness - screen_mount_clearance, 0])
      rounded_box(mount_w, mount_l, screen_mount_thickness, 1);
    
    // Отверстие под плату экрана
    translate([0, 0, -0.5])
      cube([screen_pcb_w + screen_mount_clearance * 2, screen_pcb_l + screen_mount_clearance * 2, screen_mount_thickness + 1]);
    
    // Отверстия под винты по углам
    for (pos = hole_positions) {
      translate([pos[0], pos[1], -0.5])
        cylinder(h=screen_mount_thickness + 1, d=screen_mount_hole_d);
    }
  }
  
  // Бобышки под винты (для усиления) с креплением к основанию
  for (i = [0:3]) {
    pos = hole_positions[i];
    
    // Углы рамки основания
    frame_corners = [
      [-screen_mount_thickness - screen_mount_clearance, -screen_mount_thickness - screen_mount_clearance], // Левый нижний
      [screen_pcb_w + screen_mount_thickness + screen_mount_clearance, -screen_mount_thickness - screen_mount_clearance], // Правый нижний
      [-screen_mount_thickness - screen_mount_clearance, screen_pcb_l + screen_mount_thickness + screen_mount_clearance], // Левый верхний
      [screen_pcb_w + screen_mount_thickness + screen_mount_clearance, screen_pcb_l + screen_mount_thickness + screen_mount_clearance], // Правый верхний
    ];
    
    corner = frame_corners[i];
    
    // Куб для соединения бобышки с углом основания
    // Вычисляем размеры куба от угла к бобышке
    dx = pos[0] - corner[0];
    dy = pos[1] - corner[1];
    
    // Размеры куба - расстояние от угла до центра бобышки плюс радиус бобышки
    cube_w = abs(dx) + screen_mount_boss_d / 2;
    cube_l = abs(dy) + screen_mount_boss_d / 2;
    
    // Позиция куба - начинается от угла
    // Если направление отрицательное, сдвигаем начало куба
    cube_x = (dx >= 0) ? corner[0] : corner[0] - cube_w;
    cube_y = (dy >= 0) ? corner[1] : corner[1] - cube_l;
    
    difference() {
      // Куб от угла к бобышке
      translate([cube_x, cube_y, 0])
        cube([cube_w, cube_l, screen_mount_thickness + screen_mount_boss_h]);
      
      // Бобышка (цилиндр с отверстием)
      translate([pos[0], pos[1], screen_mount_thickness])
        translate([0, 0, -5])
          cylinder(h=screen_mount_boss_h + 10, d=screen_mount_hole_d);
    }
  }
}
