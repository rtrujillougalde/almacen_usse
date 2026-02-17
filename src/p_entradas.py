import streamlit as st
import pandas as pd
from utils import get_engine, execute_sql_query

def main():
    st.header("Entradas")
    try:
        engine = get_engine()
        # Obtener nombres de artículos existentes
        query_articulos = "SELECT nombre FROM articulos;"
        df_articulos = pd.read_sql(query_articulos, engine)
        nombres_articulos = df_articulos["nombre"].tolist()

        # Obtener nombres de cables existentes
        query_cables = "SELECT nombre FROM articulos WHERE es_cable = 1;"
        df_cables = pd.read_sql(query_cables, engine)
        nombres_cables = df_cables["nombre"].tolist()
    except Exception as e:
        st.error(f"Error al obtener artículos: {e}")
        nombres_articulos = []
        nombres_cables = []

    with st.form("form_entrada"):
        st.write("Añadir nuevo item al inventario")
        # Selección o entrada de nombre de artículo
        nombre_item = st.selectbox("Selecciona un item existente o escribe uno nuevo:", nombres_articulos + ["Otro (escribir nuevo)"])
        if nombre_item == "Otro (escribir nuevo)":
            nombre_item = st.text_input("Nombre del nuevo item")

        cantidad = st.number_input("Cantidad", min_value=1, value=1)
        es_cable = st.checkbox("¿Es un cable?")

        cable_nombre = None
        cable_longitud = None
        if es_cable:
            cable_nombre = st.selectbox("Nombre del cable", nombres_cables + ["Otro (escribir nuevo)"])
            if cable_nombre == "Otro (escribir nuevo)":
                cable_nombre = st.text_input("Nombre del nuevo cable")
            cable_longitud = st.text_input("Longitud del cable (ej: 2m, 5m)")

        submitted = st.form_submit_button("Añadir al inventario")
        if submitted:
            st.success("Entrada añadida (lógica de inserción por implementar)")