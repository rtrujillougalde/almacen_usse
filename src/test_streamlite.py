


import streamlit as st
import pandas as pd
import numpy as np
import mysql.connector

def execute_sql_query(query, conn):
    try:
        
        cursor = conn.cursor()
        cursor.execute(query)
        result = cursor.fetchall()
        conn.commit()
        cursor.close()
        conn.close()
        return result
    except Exception as e:
        st.error(f"Error al ejecutar la consulta SQL: {e}")
        return None

st.set_page_config(page_title="Almacén USSE", layout="wide")

# Obtener credenciales de acceso
db_user = st.secrets["mysql"]["user"]
db_password = st.secrets["mysql"]["password"]
db_host = st.secrets["mysql"]["host"]
db_name = st.secrets["mysql"]["database"]

# Pantalla de inicio de sesión
if "logged_in" not in st.session_state:
    st.session_state.logged_in = False

if not st.session_state.logged_in:
    st.title("Iniciar sesión en Almacén USSE")
    username = st.text_input("Usuario")
    password = st.text_input("Contraseña", type="password")
    if st.button("Iniciar sesión"):
        if username == db_user and password == db_password:
            st.session_state.logged_in = True
            st.success("¡Inicio de sesión exitoso!")
            st.rerun()
        else:
            st.error("Usuario o contraseña incorrectos")
    st.stop()

# Menú lateral
st.sidebar.title("Menú")
page = st.sidebar.radio("Ir a:", ("Inventario", "Entradas", "Salidas"))

st.title('Almacen USSE')

if page == "Inventario":
    st.header("Inventario")
    try:
        conn = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            database=db_name
        )

        query = "SELECT * FROM articulos;"
        
        df_mysql = pd.read_sql(query, conn)
        st.dataframe(df_mysql)
        conn.close()
    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")

elif page == "Entradas":
    st.header("Entradas")
    if st.button("Añadir", key="entrada"):
        st.success("Funcionalidad de añadir entrada (por implementar)")

elif page == "Salidas":
    st.header("Salidas")
    if st.button("Añadir", key="salida"):
        st.success("Funcionalidad de añadir salida (por implementar)")