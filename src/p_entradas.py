import streamlit as st

from sqlalchemy.orm import sessionmaker
from utils import get_engine, get_session, categorias
from classes import Articulos, StockPuntas

def form_entrada(nombres_articulos, nombres_cables):
    
    es_cable = False
    # Initialize session state
    if 'showing_form' not in st.session_state:
        st.session_state.showing_form = False
    
    if st.button("Añadir nuevo item al inventario"):
        st.session_state.showing_form = True
    
    if st.session_state.showing_form:
        
        # Selección o entrada de nombre de artículo
        nombre_item = st.selectbox("Selecciona un item existente o escribe uno nuevo:", ["Otro (escribir nuevo)"] + nombres_articulos)
        if nombre_item == "Otro (escribir nuevo)":
            with st.expander("Detalles del nuevo item", expanded=True):
                
                nombre_item = st.text_input("Nombre del nuevo item", disabled=nombre_item != "Otro (escribir nuevo)")
                unidad_medida = st.selectbox("Unidad de medida", ["pieza", "metro", "litro", "kg"])
                stock_minimo = st.number_input("Stock mínimo para alertas", min_value=0, value=0)
                categoria = st.selectbox("Categoría", sorted(categorias))
                es_cable = st.checkbox("¿Es un cable/tramo/carrete?", value=False)
                if es_cable:
                    with st.expander("Detalles del cable", expanded=True):
                        nombre_punta = st.text_input("Nombre de la punta/carrete/tramo (e.g., 'Punta Cobre #2')", value="")
                        longitud = st.number_input("Longitud (en metros)", min_value=0.0, value=0.0, step=0.1)
                else:
                    cantidad = st.number_input("Cantidad a agregar", min_value=0, value=1)
        elif nombre_item in nombres_cables:
            with st.expander("Detalles del cable", expanded=True):
                        nombre_punta = st.text_input("Nombre de la punta/carrete/tramo (e.g., 'Punta Cobre #2')", value="")
                        longitud = st.number_input("Longitud del cable (en metros)", min_value=0.0, value=0.0, step=0.1)
        else:               
            cantidad = st.number_input("Cantidad a agregar", min_value=1, value=1)
        
        # Validation logic
        errors = []
        if not nombre_item or nombre_item == "Otro (escribir nuevo)":
            errors.append("Debe ingresar un nombre para el item")
        if nombre_item == "Otro (escribir nuevo)" or nombre_item in nombres_articulos:
            if not nombre_item or nombre_item == "Otro (escribir nuevo)":
                errors.append("Must fill in item details")
        if es_cable and longitud <= 0:
            errors.append("La longitud del cable debe ser mayor a 0")
        
        if errors:
            st.error("\n".join(["❌ " + error for error in errors]))
            submit_disabled = True
        else:
            submit_disabled = False
        
        col1, col2 = st.columns(2)
        with col1:
            if st.button("Agregar al inventario", disabled=submit_disabled):
                st.success(f'Item "{nombre_item}" agregado al inventario (simulación)')
                st.session_state.showing_form = False
        with col2:
            if st.button("Cancelar"):
                st.session_state.showing_form = False

def main():
    st.header("Entradas")
    try:
        session = get_session()
        # Obtener nombres de artículos existentes
        nombres_articulos = [row.nombre for row in session.query(Articulos).all()]
        nombres_cables = [row.nombre for row in session.query(Articulos).filter(Articulos.es_cable == 1).all()]

    except Exception as e:
        st.error(f"Error al obtener artículos: {e}")
        nombres_articulos = []
        nombres_cables = []

        
    form_entrada(nombres_articulos, nombres_cables)