"""
p_inventario.py - Página de Inventario (UI con Streamlit)

Muestra el inventario de artículos y cables, permite editar datos inline.
Toda la lógica de acceso a datos se delega al módulo data.py.
"""

import streamlit as st
import pandas as pd

from data import (
    get_all_articulos,
    update_articulo,
    get_cable_names,
    get_article_by_name,
    get_available_puntas,
)

def highlight_low_stock(row):
            if row["cantidad en stock"] < row["stock minimo"]:
                return ["background-color: #e7192b"] * len(row)
            return [""] * len(row)


def clear_inventory_filters():
    """Resetea el estado de filtros de inventario sin violar reglas de Streamlit."""
    st.session_state.inventario_categoria_filter = "Todas"
    st.session_state.inventario_tipo_filter = "Todos"
    st.session_state.inventario_nombre_filter = ""
    st.session_state.inventario_filtros_activos = False

def main():
    """
    Función principal de la página de Inventario.
    Muestra la tabla editable de artículos y la sección de cables en stock.
    """
    st.header("Inventario")

    try:
        # --- Tabla de artículos ---
        data = get_all_articulos()

        st.subheader("Articulos")

        df = pd.DataFrame(data)

        if "inventario_filtros_activos" not in st.session_state:
            st.session_state.inventario_filtros_activos = False

        categorias = sorted(df["categoria"].dropna().unique().tolist()) if "categoria" in df.columns else []
        tipos = sorted(df["tipo"].dropna().unique().tolist()) if "tipo" in df.columns else []

        st.markdown("### Filtros")
        col_f1, col_f2, col_f3 = st.columns(3)
        with col_f1:
            categoria_filter = st.selectbox(
                "Categoria",
                options=["Todas"] + categorias,
                key="inventario_categoria_filter",
            )
        with col_f2:
            tipo_filter = st.selectbox(
                "Tipo",
                options=["Todos"] + tipos,
                key="inventario_tipo_filter",
            )
        with col_f3:
            nombre_filter = st.text_input(
                "Nombre",
                key="inventario_nombre_filter",
                placeholder="Buscar por nombre...",
            )

        col_b1, col_b2 = st.columns(2)
        with col_b1:
            if st.button("Aplicar filtro", key="inventario_aplicar_filtro"):
                st.session_state.inventario_filtros_activos = True
        with col_b2:
            st.button(
                "Borrar filtros",
                key="inventario_borrar_filtros",
                on_click=clear_inventory_filters,
            )

        filtered_df = df.copy()
        if st.session_state.inventario_filtros_activos:
            if categoria_filter != "Todas" and "categoria" in filtered_df.columns:
                filtered_df = filtered_df[filtered_df["categoria"] == categoria_filter]
            if tipo_filter != "Todos" and "tipo" in filtered_df.columns:
                filtered_df = filtered_df[filtered_df["tipo"] == tipo_filter]
            if nombre_filter.strip():
                filtered_df = filtered_df[
                    filtered_df["nombre"].astype(str).str.contains(nombre_filter.strip(), case=False, na=False)
                ]

        st.caption(f"Resultados: {len(filtered_df)}")

        styled_df = filtered_df.style.apply(highlight_low_stock, axis=1).format(
            {"cantidad en stock": "{:.2f}", "stock minimo": "{:.2f}"}
        )
        if st.session_state.user_role == "consulta":
            
            st.dataframe(styled_df, hide_index=True, width='stretch')
        else:
            filtered_data = filtered_df.to_dict("records")
        
            edited_data = st.data_editor(
                filtered_data, hide_index=True,
                width='stretch',
                disabled=["id", "cantidad en stock", "tipo", "categoria"]  # No permitir editar columnas de referencia
            )

            # Guardar cambios si hubo edición
            if edited_data != filtered_data:
                try:
                    for edited_row, original_row in zip(edited_data, filtered_data):
                        if edited_row != original_row:
                            update_articulo(
                                id_articulo=edited_row["id"],
                                nombre=edited_row["nombre"],
                                num_catalogo=edited_row["num_catalogo"],
                                cantidad_en_stock=edited_row["cantidad en stock"],
                                unidad_medida=edited_row["unidad de medida"],
                                stock_minimo=edited_row["stock minimo"],
                            )
                    st.success("Cambios guardados")
                except Exception as e:
                    st.error(f"Error al guardar cambios: {e}")

        # --- Sección de cables ---
        cable_names = get_cable_names()

        st.subheader("Cables en stock")
        selected_cable = st.selectbox("Selecciona un cable", cable_names)

        if selected_cable:
            cable = get_article_by_name(selected_cable)
            if cable:
                cable_puntas = get_available_puntas(cable.id_articulo)
                formatted_puntas = [
                    {
                        "nombre de punta": punta["nombre_punta"],
                        "longitud": punta["longitud"],
                    }
                    for punta in cable_puntas
                ]
                st.dataframe(formatted_puntas)

    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")