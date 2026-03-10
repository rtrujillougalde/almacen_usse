
"""
main_almacen.py - Punto de entrada principal de la aplicación Almacén USSE

Configura la página, maneja la autenticación y gestiona la navegación
entre las secciones: Inventario, Entradas, Salidas, Proyectos y Reportes.
"""

import streamlit as st
from utils import db_user, db_password
from p_entradas import main as entradas_main
from p_inventario import main as inventario_main
from p_salidas import main as salidas_main
from p_proyectos import main as proyectos_main
from p_reportes import main as reportes_main, reporte_salidas_main
st.set_page_config(page_title="Almacén USSE", layout="centered")



# Pantalla de inicio de sesión
if "logged_in" not in st.session_state:
    st.session_state.logged_in = True

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
page = st.sidebar.radio("Ir a:", ("Inventario", "Entradas", "Salidas", "Proyectos", "Reportes"))


st.title('Almacén USSE')

if page == "Inventario":
    inventario_main()
    
elif page == "Entradas":
    entradas_main()

elif page == "Salidas":
    salidas_main()

elif page == "Proyectos":
    proyectos_main()
    st.info("Funcionalidad de Proyectos en desarrollo")

elif page == "Reportes":
    pdf = reportes_main()
    reporte_salidas_main()

    st.info("Funcionalidad de Reportes en desarrollo")