"""
utils.py - Utilidades de configuración y conexión a base de datos

Contiene la configuración de conexión a MySQL, la creación del engine
de SQLAlchemy, y constantes compartidas (categorías, unidades de medida).
"""

import streamlit as st
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# =============================================================================
# CONSTANTES
# =============================================================================

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


def get_engine():
    """
    Crea y devuelve un engine de SQLAlchemy para la conexión a MySQL.

    Returns:
        sqlalchemy.engine.Engine: Engine configurado.
    """
    return create_engine(
        f"mysql+mysqlconnector://{db_user}:{db_password}@{db_host}/{db_name}"
    )


def get_session():
    """
    Crea y devuelve una nueva sesión de SQLAlchemy.

    Returns:
        sqlalchemy.orm.Session: Sesión activa.
    """
    engine = get_engine()
    Session = sessionmaker(bind=engine)
    return Session()


def execute_sql_query(query, params=None):
    """
    Ejecuta una consulta SQL directa y devuelve los resultados.

    Args:
        query (str): Consulta SQL a ejecutar.
        params (dict, optional): Parámetros para la consulta.

    Returns:
        list | None: Lista de filas resultantes, o None si ocurre un error.

    Raises:
        Exception: Si ocurre un error al ejecutar la consulta.
    """
    engine = get_engine()
    with engine.connect() as connection:
        result = connection.execute(text(query), params or {})
        return result.fetchall()