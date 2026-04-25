"""
p_inventario.py - Página de Inventario (UI con Streamlit)

Muestra el inventario de artículos y cables, permite editar datos inline.
Toda la lógica de acceso a datos se delega al módulo data.py.
"""

import streamlit as st
import pandas as pd
from types import SimpleNamespace
from utils import CATEGORIAS, UNIDAD_DE_MEDIDA, UBICACIONES, ALMACENES
from user_passwords import verify_credentials
from data import (
    get_all_articulos,
    update_articulo,
    get_cable_names,
    get_article_by_name,
    get_available_puntas,
    get_proveedor_names,
    get_proveedores_for_edit,
)

def highlight_low_stock(row):
            if row["cantidad en stock"] < row["stock minimo"]:
                return ["background-color: #EB6E6E"] * len(row)
            return [""] * len(row)


def clear_inventory_filters():
    """Resetea el estado de filtros de inventario sin violar reglas de Streamlit."""
    st.session_state.inventario_categoria_filter = "Todas"
    st.session_state.inventario_tipo_filter = "Todos"
    st.session_state.inventario_nombre_filter = ""
    st.session_state.inventario_filtros_activos = False

#@st.dialog("Contraseña requerida")
def password_required_dialog():
    st.warning("Para modificar la cantidad en stock, por favor ingresa contraseña del administrador.")
    password = st.text_input("Contraseña", type="password")
    return password

@st.dialog("Editar artículo")
def editar_articulo_dialog(articulo):
    with st.form("form_editar_articulo"):
        nombre = st.text_input("Nombre *", value=articulo.get("nombre") or "")
        num_catalogo = st.text_input("Núm. catálogo", value=articulo.get("num_catalogo") or "")
        cantidad = st.number_input("Cantidad en stock", value=float(articulo.get("cantidad en stock") or 0), min_value=0.0)
        unidad = st.selectbox("Unidad de medida", options=UNIDAD_DE_MEDIDA,
                              index=UNIDAD_DE_MEDIDA.index(articulo["unidad de medida"]) if articulo.get("unidad de medida") in UNIDAD_DE_MEDIDA else 0)
        stock_min = st.number_input("Stock mínimo", value=float(articulo.get("stock minimo") or 0), min_value=0.0)
        tipo = st.text_input("Tipo", value=articulo.get("tipo") or "")
        categoria = st.selectbox("Categoría", options=CATEGORIAS,
                                 index=CATEGORIAS.index(articulo["categoria"]) if articulo.get("categoria") in CATEGORIAS else 0)
        es_cable = st.checkbox("Es cable", value=bool(articulo.get("es_cable")))
        almacen = st.selectbox("Almacén", options=ALMACENES,
                               index=ALMACENES.index(articulo["almacen"]) if articulo.get("almacen") in ALMACENES else 0)
        ubicacion = st.selectbox("Ubicación", options=UBICACIONES,
                                 index=UBICACIONES.index(articulo["ubicacion"]) if articulo.get("ubicacion") in UBICACIONES else 0)
        proveedores = get_proveedor_names()
        proveedor_idx = proveedores.index(articulo["proveedor"]) if articulo.get("proveedor") in proveedores else 0
        proveedor = st.selectbox("Proveedor", options=proveedores, index=proveedor_idx)

        st.divider()
        st.caption("Si modificas la cantidad en stock, ingresa la contraseña de administrador.")
        confirm_password = st.text_input("Contraseña de administrador", type="password")

        submitted = st.form_submit_button("Guardar cambios")

    if submitted:
        if not nombre.strip():
            st.error("El campo Nombre es obligatorio.")
            return

        cantidad_original = float(articulo.get("cantidad en stock") or 0)
        if cantidad != cantidad_original:
            if verify_credentials("admin", confirm_password) is None:
                st.error("Contraseña incorrecta. No se puede modificar la cantidad.")
                return
            
        try:
            update_articulo(
                id_articulo=articulo["id"],
                nombre=nombre,
                num_catalogo=num_catalogo,
                cantidad_en_stock=cantidad,
                unidad_medida=unidad,
                stock_minimo=stock_min,
                tipo=tipo,
                categoria=categoria,
                es_cable=es_cable,
                almacen=almacen,
                ubicacion=ubicacion,
                proveedor_name=proveedor,
            )
            st.success("Artículo actualizado exitosamente.")
            st.rerun()
        except Exception as e:
            st.error(f"Error al actualizar artículo: {e}")
            
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

        
        tipos = sorted(df["tipo"].dropna().unique().tolist()) if "tipo" in df.columns else []

        st.markdown("### Filtros")
        col_f1, col_f2, col_f3 = st.columns(3)
        with col_f1:
            categoria_filter = st.selectbox(
                "Categoria",
                options=["Todas"] + CATEGORIAS,
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
        articulos_edit = {f"{a['id']} - {a['nombre']}": a for a in data}
        seleccionado = st.selectbox("Artículo a editar", options=list(articulos_edit.keys()), key="articulo_editar_select")
        if st.button("✏️ Editar artículo seleccionado"):
            editar_articulo_dialog(articulos_edit[seleccionado])

        st.dataframe(styled_df, hide_index=True, width='stretch')
        
        # Selector para editar artículo
       

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
                        "color": punta["color"]
                    }
                    for punta in cable_puntas
                ]
                st.dataframe(formatted_puntas)

    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")