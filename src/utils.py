"""
utils.py - Utilidades de configuración y conexión a base de datos

Contiene la configuración de conexión a MySQL, la creación del engine
de SQLAlchemy, y constantes compartidas (categorías, unidades de medida).
"""
from pathlib import Path
import streamlit as st
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# =============================================================================
# CONSTANTES
# =============================================================================
LOGO_PATH = Path(__file__).resolve().parent.parent / "images" / "logo_usse_2.jpg"
categorias = [
    'albañileria', 'aire_acondicionado', 'aislantes',
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
    'tableros', 'tierras', 'tornilleria', 'zapatas',
]

unidad_de_medida = ['pza', 'm', 'lt', 'kg']

# =============================================================================
# CONEXIÓN A BASE DE DATOS
# =============================================================================

db_user = st.secrets["mysql_local"]["user"]
db_password = st.secrets["mysql_local"]["password"]
db_host = st.secrets["mysql_local"]["host"]
db_name = st.secrets["mysql_local"]["database"]



def get_session():
    """
    Crea y devuelve una nueva sesión de SQLAlchemy.

    Returns:
        sqlalchemy.orm.Session: Sesión activa.
    """
    engine = create_engine(
        f"mysql+mysqlconnector://{db_user}:{db_password}@{db_host}/{db_name}",
        pool_pre_ping=True
    )

    Session = sessionmaker(bind=engine)
    return Session()


