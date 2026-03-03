# Obtener credenciales de acceso
import streamlit as st
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from classes import Articulos, Movimientos, DetalleMovimiento, StockPuntas
categorias = ['albañileria', 'aire_acondicionado', 'aislantes',
               'almacen_dormitorios', 'alumbrado', 'baterias', 
               'c_d', 'cables', 'calentadores', 'canalizaciones', 
               'charolas', 'cinchos', 'conductor', 'contactos', 'contactos_regulados', 
               'control_almacen', 'control_acceso', 'datos', 'eléctrico',
                 'equipo_medición', 'equipo_protección', 'fibra_óptica', 
                 'fuse_panel', 'fusibles', 'gasolina', 'general', 
                 'herramienta', 'herrería', 'interruptores', 'kit_cursos', 
                 'limpieza', 'miscelaneos', 'motores', 'papelería', 'pintura', 
                 'planta_emergencia', 'plomeria', 'racks', 'referencia', 
                 'registros', 'regletas', 'seguridad', 'soportes', 'tablaroca',
                'tableros', 'tierras', 'tornilleria', 'zapatas']

unidad_de_medida = ['pza', 'm', 'lt', 'kg']

db_user = st.secrets["mysql_local"]["user"]
db_password = st.secrets["mysql_local"]["password"]
db_host = st.secrets["mysql_local"]["host"]
db_name = st.secrets["mysql_local"]["database"]

# Nueva función para obtener el engine de SQLAlchemy
def get_engine():
    return create_engine(f"mysql+mysqlconnector://{db_user}:{db_password}@{db_host}/{db_name}")
def get_session():
    engine = get_engine()
    Session = sessionmaker(bind=engine)
    return Session()
def execute_sql_query(query, params=None):
    engine = get_engine()
    with engine.connect() as connection:
        try:
            result = connection.execute(text(query), params or {})
            return result.fetchall()
        except Exception as e:
            st.error(f"Error al ejecutar la consulta SQL: {e}")
            return None

def get_cables_without_salida():
    """Get list of cable puntas excluding those with salida movements."""
    session = get_session()
    
    # Get puntas with salida movements
    puntas_with_salida = session.query(DetalleMovimiento.id_punta).join(
        Movimientos, DetalleMovimiento.id_movimiento == Movimientos.id_movimiento
    ).filter(Movimientos.tipo == "salida").distinct().all()
    
    salida_punta_ids = {row.id_punta for row in puntas_with_salida}
    
    # Get all puntas associated with cables (es_cable == 1)
    cable_puntas = session.query(StockPuntas).join(
        Articulos, StockPuntas.id_articulo == Articulos.id_articulo
    ).filter(Articulos.es_cable == 1).all()
    
    # Filter puntas excluding those with salida movements
    available_puntas = [punta.nombre_punta for punta in cable_puntas if punta.id_punta not in salida_punta_ids]
    session.close()
    return available_puntas

def get_cable_names():
    """Get list of cable names."""
    session = get_session()
    cables = session.query(Articulos.nombre).filter(Articulos.es_cable == 1).all()
    cable_names = [row.nombre for row in cables]
    session.close()
    return cable_names