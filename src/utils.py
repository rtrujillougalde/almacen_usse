# Obtener credenciales de acceso
import streamlit as st
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
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


db_user = st.secrets["mysql"]["user"]
db_password = st.secrets["mysql"]["password"]
db_host = st.secrets["mysql"]["host"]
db_name = st.secrets["mysql"]["database"]

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