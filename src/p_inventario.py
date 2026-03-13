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
    get_available_cable_puntas,
)

def highlight_low_stock(row):
            if row["cantidad en stock"] < row["stock minimo"]:
                return ["background-color: #ffcccc"] * len(row)
            return [""] * len(row)

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

        

        styled_df = df.style.apply(highlight_low_stock, axis=1).format(
            {"cantidad en stock": "{:.2f}", "stock minimo": "{:.2f}"}
        )
        st.dataframe(styled_df, hide_index=True, use_container_width=True)

        with st.expander("Editar artículos"):
            edited_data = st.data_editor(
                data, hide_index=True,
                use_container_width=True,
                disabled=["id","cantidad en stock"]  # No permitir editar el ID
            )

        # Guardar cambios si hubo edición
        if edited_data != data:
            try:
                for edited_row, original_row in zip(edited_data, data):
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
            cable_puntas = get_available_cable_puntas(selected_cable)
            st.dataframe(cable_puntas)

    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")