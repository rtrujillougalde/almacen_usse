CREATE DATABASE  IF NOT EXISTS `local_almacen` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `local_almacen`;
-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: local_almacen
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `detalle_movimientos`
--

DROP TABLE IF EXISTS `detalle_movimientos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_movimientos`
--

LOCK TABLES `detalle_movimientos` WRITE;
/*!40000 ALTER TABLE `detalle_movimientos` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_movimientos` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-25 11:23:22
