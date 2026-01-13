$fn = 64; // Качество окружностей

// Параметры куба
CUBE_SIZE = 300; // Размер куба (300x300x300 мм)
WALL_THICKNESS = 2; // Толщина стенок

// Создаем полый куб без верхней крышки
difference() {
  // Внешний куб
  cube([CUBE_SIZE, CUBE_SIZE, CUBE_SIZE]);

  // Вырезаем внутреннюю полость (верх открыт)
  translate([WALL_THICKNESS, WALL_THICKNESS, WALL_THICKNESS])
    cube(
      [
        CUBE_SIZE - WALL_THICKNESS * 2,
        CUBE_SIZE - WALL_THICKNESS * 2,
        CUBE_SIZE + 0.1,
      ]
    );
  // Вырезаем до верха, чтобы верх был открыт
}
