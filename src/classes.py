from sqlalchemy.orm import declarative_base
from sqlalchemy import Column, Integer, String, Float, Boolean, Enum,ForeignKey
import enum
Base = declarative_base()
class CatEnum(enum.Enum):
    cable = "cable"
    componente = "componente"
    albañileria = 'albañileria'
    aire_acondicionado = 'aire_acondicionado'
    aislantes = 'aislantes'
    almacen_dormitorios = 'almacen_dormitorios'
    alumbrado = 'alumbrado'
    baterias = 'baterias'
    c_d = 'c_d'
    cables = 'cables'
    calentadores = 'calentadores'
    canalizaciones = 'canalizaciones'
    charolas = 'charolas'
    cinchos = 'cinchos'
    conductor = 'conductor'
    contactos = 'contactos'
    contactos_regulados = 'contactos_regulados'
    control_almacen = 'control_almacen'
    control_acceso = 'control_acceso'
    datos = 'datos'
    electrico = 'eléctrico'
    equipo_medicion = 'equipo_medición'
    equipo_proteccion = 'equipo_protección'
    fibra_optica = 'fibra_óptica'
    fuse_panel = 'fuse_panel'
    fusibles = 'fusibles'
    gasolina = 'gasolina'
    general = 'general'
    herramienta = 'herramienta'
    herreria = 'herreria'
    interruptores = 'interruptores'
    kit_cursos = 'kit para cursos'
    limpieza = 'limpieza'
    miscelaneos = 'miscelaneos'
    motores = 'motores'
    papelería = 'papelería'
    pintura = 'pintura'
    planta_emergencia = 'planta_emergencia'
    plomeria = 'plomeria'
    racks = 'racks'
    referencia = 'referencia'
    registros = 'registros'
    regletas = 'regletas'
    seguridad = 'seguridad'
    soportes = 'soportes'
    tablaroca = 'tablaroca'
    tableros = 'tableros'
    tierras = 'tierras'
    tornilleria = 'tornilleria'
    zapatas = 'zapatas'

class TipoEnum(enum.Enum):
    material = "material"
    herramienta = "herramienta"

class Articulos(Base):
    __tablename__ = 'articulos'
    id_articulo= Column(Integer, primary_key=True)
    nombre = Column(String)
    tipo = Column(Enum(TipoEnum)) # 'Material' o 'Herramienta'
    cantidad_en_stock = Column(Integer)
    unidad_medida = Column(String)
    es_cable = Column(Boolean) # 1 para sí, 0 para no
    categoria = Column(Enum(CatEnum)) # 'cable' o 'componente'
    stock_minimo = Column(Float) # Cantidad mínima para alertas de stock bajo
    precio_unitario = Column(Float) # Precio por unidad, útil para calcular el valor total del inventario
    # Add other columns as needed 

class DetalleMovimiento(Base):
    __tablename__ = 'detalle_movimiento'
    id_detalle = Column(Integer, primary_key=True)
    id_movimiento = Column(Integer, ForeignKey('movimientos.id_movimiento'))
    id_articulo = Column(Integer, ForeignKey('articulos.id_articulo'))
    cantidad = Column(Integer)
    precio_unitario = Column(Float) # Precio por unidad en el momento del movimiento

class Movimientos(Base):
    __tablename__ = 'movimientos'
    id_movimiento = Column(Integer, primary_key=True)
    id_proyecto = Column(Integer, ForeignKey('proyectos.id_proyecto')) # Proyecto asociado al movimiento
    tipo = Column(Enum(TipoEnum)) # 'Entrada' o 'Salida'
    fecha_hora = Column(String) # Fecha del movimiento
    observaciones = Column(String) # Detalles adicionales sobre el movimiento

class Proyectos(Base):
    __tablename__ = 'proyectos'
    id_proyecto = Column(Integer, primary_key=True) #project or work identifier
    c_c = Column(Integer) # Cost center 
    nombre_obra = Column(String) 
    encargado = Column(String) 

class StockPuntas(Base):
    __tablename__ = 'stock_puntas'
    id_punta = Column(Integer, primary_key=True)
    id_articulo = Column(Integer, ForeignKey('articulos.id_articulo')) # Tipo de punta (e.g., punta de destornillador, punta de taladro, etc.)
    longitud = Column(Float) # Cantidad actual en stock
    nombre_punta = Column(String) # Nombre descriptivo de la punta (e.g., "Punta Phillips #2", "Punta de Taladro 5mm", etc.)