
"""
main_almacen.py - Punto de entrada principal de la aplicación Almacén USSE

Configura la página, maneja la autenticación y gestiona la navegación
entre las secciones: Inventario, Entradas, Salidas, Proyectos y Reportes.
"""

import streamlit as st
from utils import LOGO_PATH
from user_passwords import main as login_main, logout, get_allowed_pages
from p_entradas import main as entradas_main
from p_inventario import main as inventario_main
from p_salidas import main as salidas_main
from p_proyectos import main as proyectos_main
from p_reportes import reporte_entradas_main, reporte_salidas_main, reporte_comparacion_main


st.set_page_config(page_title="Almacén USSE", page_icon=str(LOGO_PATH), layout="centered")

# ── Autenticación ────────────────────────────────────────
login_main()

# ── Sidebar: usuario, logout y navegación por rol ────────
st.sidebar.image(str(LOGO_PATH), width=200)
st.sidebar.title("Menú")
st.sidebar.caption(f"Sesión: {st.session_state.authenticated_user}  ({st.session_state.user_role})")

if st.sidebar.button("Cerrar sesión", use_container_width=True):
    logout()

allowed_pages = get_allowed_pages(st.session_state.user_role)
page = st.sidebar.radio("Ir a:", allowed_pages)

# ── Contenido ────────────────────────────────────────────
st.title('Almacén USSE')
st.image(str(LOGO_PATH), width=240)

if page == "Inventario":
    inventario_main()

elif page == "Entradas":
    entradas_main()

elif page == "Salidas":
    salidas_main()

elif page == "Proyectos":
    proyectos_main()
    

elif page == "Reportes":
    reporte_entradas_main()
    reporte_salidas_main()
    reporte_comparacion_main()
    st.info("Funcionalidad de Reportes en desarrollo")