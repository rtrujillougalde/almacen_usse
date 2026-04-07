
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
from p_reportes import main as reportes_main
from p_proveedores import main as proveedores_main


st.set_page_config(page_title="Almacén USSE", page_icon=str(LOGO_PATH), layout="wide")

# ── Autenticación ────────────────────────────────────────
login_main()

# ── Sidebar: usuario, logout y navegación por rol ────────
st.sidebar.markdown(
    f'<div style="text-align:center"><img src="data:image/png;base64,'
    f'{__import__("base64").b64encode(open(str(LOGO_PATH),"rb").read()).decode()}'
    f'" width="180"></div>',
    unsafe_allow_html=True,
)
st.sidebar.title("Menú")
st.sidebar.caption(f"Sesión: {st.session_state.user_role}")

if st.sidebar.button("Cerrar sesión", width='stretch'):
    logout()

allowed_pages = get_allowed_pages(st.session_state.user_role)
page = st.sidebar.radio("Ir a:", allowed_pages)

# ── Contenido ────────────────────────────────────────────

col1, col2, col3 = st.columns([1, 2, 1])
with col2:
    
    st.image(str(LOGO_PATH))
    st.title('Almacén USSE',text_alignment="center")

if page == "Inventario":
    inventario_main()

elif page == "Entradas":
    entradas_main()

elif page == "Salidas":
    salidas_main()

elif page == "Proyectos":
    proyectos_main()
    
elif page == "Reportes":
    reportes_main()

elif page == "Proveedores":
    proveedores_main()
    