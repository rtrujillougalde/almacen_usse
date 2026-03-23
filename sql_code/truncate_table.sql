-- Reset de tablas para Almacén USSE (MySQL)
-- Desactiva validación de claves foráneas, elimina tablas y reactiva validación.

-- Opcional: selecciona tu base de datos
-- USE nombre_de_tu_base_de_datos;

SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE IF EXISTS detalle_movimientos;
ALTER TABLE IF EXISTS movimientos;
ALTER TABLE IF EXISTS stock_puntas;
ALTER TABLE IF EXISTS articulos;
ALTER TABLE IF EXISTS proyectos;

SET FOREIGN_KEY_CHECKS = 1;
