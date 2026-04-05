CREATE TABLE `articulos` (
  `id_articulo` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `catalogo` varchar(100),
  `tipo` enum('material','herramienta') NOT NULL,
  `cantidad_en_stock` float DEFAULT NULL,
  `unidad_medida` varchar(50) CHARACTER SET armscii8 COLLATE armscii8_general_ci DEFAULT NULL,
  `es_cable` tinyint(1) DEFAULT '0',
  `categoria` enum('albañileria','aire_acondicionado','aislantes','almacen_dormitorios','alumbrado','baterias','c_d','cables','calentadores','canalizaciones','charolas','cinchos','conductor','contactos','contactos_regulados','control_almacen','control_acceso','datos','eléctrico','equipo_medición','equipo_protección','fibra_óptica','fuse_panel','fusibles','gasolina','general','herramienta','herrería','interruptores','kit_cursos','limpieza','miscelaneos','motores','papelería','pintura','planta_emergencia','plomeria','racks','referencia','registros','regletas','seguridad','soportes','tablaroca','tableros','tierras','tornilleria','zapatas') DEFAULT NULL,
  `stock_minimo` float DEFAULT NULL,
  `precio_unitario` float DEFAULT NULL,
  PRIMARY KEY (`id_articulo`)
) ;
CREATE TABLE `proyectos` (
  `id_proyecto` int NOT NULL AUTO_INCREMENT,
  `c_c` int NOT NULL,
  `nombre_obra` varchar(150) DEFAULT NULL,
  `encargado` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id_proyecto`),
  UNIQUE KEY `codigo_obra` (`c_c`)
) ;

CREATE TABLE `movimientos` (
  `id_movimiento` int NOT NULL AUTO_INCREMENT,
  `id_proyecto` int DEFAULT NULL,
  `tipo` enum('entrada','salida') NOT NULL,
  `fecha_hora` datetime DEFAULT CURRENT_TIMESTAMP,
  `observaciones` text,
  `responsable` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id_movimiento`),
  KEY `id_proyecto` (`id_proyecto`),
  CONSTRAINT `movimientos_ibfk_1` FOREIGN KEY (`id_proyecto`) REFERENCES `proyectos` (`id_proyecto`)
) ;
CREATE TABLE `stock_puntas` (
  `id_punta` int NOT NULL AUTO_INCREMENT,
  `id_articulo` int NOT NULL,
  `nombre_punta` varchar(45) DEFAULT NULL,
  `longitud` decimal(10,2) NOT NULL,
  `color` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`id_punta`),
  KEY `inventario_stock_ibfk_1` (`id_articulo`),
  CONSTRAINT `stock_puntas_ibfk_1` FOREIGN KEY (`id_articulo`) REFERENCES `articulos` (`id_articulo`)
) ;

CREATE TABLE `detalle_movimientos` (
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_movimiento` int NOT NULL,
  `id_articulo` int NOT NULL,
  `id_punta` int DEFAULT NULL,
  `cantidad` float NOT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `detalle_movimientos_ibfk_3_idx` (`id_articulo`),
  KEY `detalle_movimientos_ibfk_1` (`id_movimiento`),
  KEY `detalle_movimientos_ibfk_2` (`id_punta`),
  CONSTRAINT `detalle_movimientos_ibfk_1` FOREIGN KEY (`id_movimiento`) REFERENCES `movimientos` (`id_movimiento`),
  CONSTRAINT `detalle_movimientos_ibfk_2` FOREIGN KEY (`id_punta`) REFERENCES `stock_puntas` (`id_punta`),
  CONSTRAINT `detalle_movimientos_ibfk_3` FOREIGN KEY (`id_articulo`) REFERENCES `articulos` (`id_articulo`)
) ;



