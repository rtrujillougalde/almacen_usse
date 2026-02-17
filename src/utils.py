# Obtener credenciales de acceso
import streamlit as st
from sqlalchemy import create_engine, text

db_user = st.secrets["mysql"]["user"]
db_password = st.secrets["mysql"]["password"]
db_host = st.secrets["mysql"]["host"]
db_name = st.secrets["mysql"]["database"]

# Nueva función para obtener el engine de SQLAlchemy
def get_engine():
    return create_engine(f"mysql+mysqlconnector://{db_user}:{db_password}@{db_host}/{db_name}")

# Ejecutar consulta SQL con SQLAlchemy
def execute_sql_query(query, params=None):
    engine = get_engine()
    with engine.connect() as connection:
        try:
            result = connection.execute(text(query), params or {})
            return result.fetchall()
        except Exception as e:
            st.error(f"Error al ejecutar la consulta SQL: {e}")
            return None