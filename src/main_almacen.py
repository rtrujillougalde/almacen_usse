


import streamlit as st
import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
from utils import get_engine, execute_sql_query, db_user, db_password, db_host, db_name
from p_entradas import main as entradas_main
from p_inventario import main as inventario_main
from p_salidas import main as salidas_main

st.set_page_config(page_title="Almacén USSE", layout="wide")



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


st.title('Almacén USSE')

if page == "Inventario":
    inventario_main()
elif page == "Entradas":
    entradas_main()

elif page == "Salidas":
    salidas_main()