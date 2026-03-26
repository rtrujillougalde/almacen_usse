-- Reset de tablas para Almacén USSE (MySQL)
-- Desactiva validación de claves foráneas, elimina tablas y reactiva validación.

-- Opcional: selecciona tu base de datos
-- USE nombre_de_tu_base_de_datos;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE detalle_movimientos;
TRUNCATE TABLE movimientos;
TRUNCATE TABLE stock_puntas;
TRUNCATE TABLE articulos;
TRUNCATE TABLE proyectos;

SET FOREIGN_KEY_CHECKS = 1;
