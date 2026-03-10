"""
p_proyectos.py - Página de Gestión de Proyectos (UI con Streamlit)

Permite crear nuevos proyectos con centro de costo, nombre de obra y encargado.
Toda la lógica de acceso a datos se delega al módulo data.py.
"""

import streamlit as st

from data import add_proyecto


def main():
    """
    Función principal de la página de Proyectos.
    Muestra un botón para abrir el formulario de nuevo proyecto
    y gestiona su creación en la base de datos.
    """
    st.title("Gestión de Proyectos")

    # Inicializar estado de visibilidad del formulario
    if "mostrar_form_proyecto" not in st.session_state:
        st.session_state.mostrar_form_proyecto = False

    # Botón para alternar visibilidad del formulario
    if st.button("➕ Añadir Proyecto"):
        st.session_state.mostrar_form_proyecto = (
            not st.session_state.mostrar_form_proyecto
        )
        st.rerun()

    st.divider()

    # Mostrar formulario solo si el botón fue presionado
    if st.session_state.mostrar_form_proyecto:
        with st.form("form_proyecto"):
            c_c = st.number_input("Centro de Costo (C.C.)", min_value=0, step=1)
            nombre_obra = st.text_input("Nombre de la Obra")
            encargado = st.text_input("Encargado del Proyecto")
            submitted = st.form_submit_button("Guardar Proyecto")

            if submitted:
                if c_c and nombre_obra and encargado:
                    try:
                        add_proyecto(c_c, nombre_obra, encargado)
                        st.success(
                            f"Proyecto '{nombre_obra}' agregado exitosamente."
                        )
                        st.session_state.mostrar_form_proyecto = False
                        st.rerun()
                    except Exception as e:
                        st.error(f"Error al agregar proyecto: {e}")
                else:
                    st.error(
                        "Por favor, complete todos los campos del formulario."
                    )