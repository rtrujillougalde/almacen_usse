import streamlit as st
import pandas as pd
from time import sleep
from sqlalchemy.orm import sessionmaker
from utils import get_engine, get_session, categorias, unidad_de_medida
from classes import Articulos, StockPuntas, Movimientos, DetalleMovimiento, Proyectos

def main():
    st.title("Gestión de Proyectos")
    session = get_session()
    
    # Initialize session state for form visibility
    if 'mostrar_form_proyecto' not in st.session_state:
        st.session_state.mostrar_form_proyecto = False
    
    # Button to toggle form visibility
    if st.button("➕ Añadir Proyecto"):
        st.session_state.mostrar_form_proyecto = not st.session_state.mostrar_form_proyecto
        st.rerun()
    
    st.divider()
    
    # Show form only if button was clicked
    if st.session_state.mostrar_form_proyecto:
        with st.form("form_proyecto"):
            c_c = st.number_input("Centro de Costo (C.C.)", min_value=0, step=1)
            nombre_obra = st.text_input("Nombre de la Obra")
            encargado = st.text_input("Encargado del Proyecto")
            submitted = st.form_submit_button("Guardar Proyecto")
            
            if submitted:
                if c_c and nombre_obra and encargado:
                    nuevo_proyecto = Proyectos(c_c=c_c, nombre_obra=nombre_obra, encargado=encargado)
                    session.add(nuevo_proyecto)
                    session.commit()
                    st.success(f"Proyecto '{nombre_obra}' agregado exitosamente.")
                    st.session_state.mostrar_form_proyecto = False  # Hide form after successful submission
                    st.rerun()
                else:
                    st.error("Por favor, complete todos los campos del formulario.")