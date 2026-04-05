"""
p_reportes.py - Página de Reportes (UI con Streamlit)

Contiene la interfaz de usuario para generar reportes PDF de entradas y salidas,
con filtros por fecha y centro de costo.
Toda la lógica de acceso a datos y generación de PDF se delega a data.py.
"""

import streamlit as st
import pandas as pd
import datetime

from data import (
    get_all_cc,
    get_entradas_data,
    get_salidas_data,
    get_comparacion_data,
    create_entradas_pdf,
    create_entradas_excel,
    create_salidas_pdf,
    create_salidas_excel,
    create_comparacion_pdf,
    create_comparacion_excel,
)


# =============================================================================
# HELPERS DE UI
# =============================================================================

def render_filter_section(key_prefix=""):
    """
    Renderiza la sección de filtros (centro de costo y opcionalmente fechas).

    Args:
        key_prefix (str): Prefijo para las claves de los widgets (evita conflictos).

    Returns:
        tuple: (fecha_inicio_str, fecha_fin_str, cc_selected,
                fecha_inicio, fecha_fin, cc_seleccionados)
    """
    

    filtrar_fechas = st.checkbox(
        "Filtrar por rango de fechas",
        value=False,
        key=f"{key_prefix}filtrar_fechas",
    )

    fecha_inicio = None
    fecha_fin = None
    fecha_inicio_str = None
    fecha_fin_str = None

    if filtrar_fechas:
        col1, col2 = st.columns(2)
        with col1:
            fecha_inicio = st.date_input(
                "Fecha de inicio",
                value=datetime.date(datetime.datetime.now().year, 1, 1),
                key=f"{key_prefix}fecha_inicio",
            )
        with col2:
            fecha_fin = st.date_input(
                "Fecha de fin",
                value=datetime.date.today(),
                key=f"{key_prefix}fecha_fin",
            )
        fecha_inicio_str = fecha_inicio.strftime("%Y-%m-%d")
        fecha_fin_str = fecha_fin.strftime("%Y-%m-%d")

    

    return (
        fecha_inicio_str,
        fecha_fin_str,
        fecha_inicio,
        fecha_fin
    )


def build_report_filename(report_type, fecha_inicio, fecha_fin, cc_seleccionados, extension="pdf"):
    """
    Construye el nombre del archivo con el rango de fechas y centros de costo.

    Args:
        report_type (str): Tipo de reporte ('entradas', 'salidas', 'comparativo').
        fecha_inicio: Objeto date de inicio.
        fecha_fin: Objeto date de fin.
        cc_seleccionados (int | str): Centro de costo seleccionado.
        extension (str): Extensión del archivo ('pdf' o 'xlsx').

    Returns:
        str: Nombre del archivo formateado.
    """
    cc_str = f"_cc_{cc_seleccionados}" if cc_seleccionados else ""
    fecha_str = (
        f"_{fecha_inicio.strftime('%d%m%Y')}_a_{fecha_fin.strftime('%d%m%Y')}"
        if fecha_inicio and fecha_fin
        else ""
    )
    return f"reporte_{report_type}{fecha_str}{cc_str}.{extension}"


def create_preview_dataframe_entradas(entradas_data):
    """
    Crea un DataFrame de vista previa a partir de datos de entradas.

    Args:
        entradas_data (list[tuple]): Datos de entradas.

    Returns:
        pd.DataFrame: DataFrame formateado para visualización.
    """
    preview_df = []
    for entrada in entradas_data:
        fecha_hora, cc, material, cantidad, precio_unitario, observaciones = entrada
        total = cantidad * (precio_unitario or 0)
        preview_df.append({
            "Fecha/Hora": fecha_hora,
            "C.C": cc,
            "Material": material,
            "Cantidad": cantidad,
            "Precio Unit.": f"${precio_unitario:.2f}" if precio_unitario else "$0.00",
            "Total": f"${total:.2f}",
        })
    return pd.DataFrame(preview_df)


def create_preview_dataframe_salidas(salidas_data):
    """
    Crea un DataFrame de vista previa a partir de datos de salidas.

    Args:
        salidas_data (list[tuple]): Datos de salidas.

    Returns:
        pd.DataFrame: DataFrame formateado para visualización.
    """
    preview_df = []
    for salida in salidas_data:
        fecha_hora, cc, material, cantidad, nombre_punta, longitud, observaciones = salida
        if nombre_punta:
            detalle = (
                f"{nombre_punta} ({longitud}m)" if longitud else nombre_punta
            )
        else:
            detalle = f"{cantidad}"

        preview_df.append({
            "Fecha/Hora": fecha_hora,
            "C.C": cc,
            "Material": material,
            "Cantidad": cantidad if not nombre_punta else "Punta",
            "Detalle": detalle,
        })
    return pd.DataFrame(preview_df)


def display_report_results(entradas_data, pdf_buffer, excel_buffer, pdf_name, excel_name):
    """
    Muestra los botones de descarga (PDF y Excel) y la vista previa de datos de entradas.
    """
    st.success(f"Se encontraron {len(entradas_data)} registros de entrada")

    col1, col2 = st.columns(2)
    with col1:
        st.download_button(
            label="📄 Descargar PDF",
            data=pdf_buffer,
            file_name=pdf_name,
            mime="application/pdf",
            key="download_entradas_pdf",
        )
    with col2:
        st.download_button(
            label="📊 Descargar Excel",
            data=excel_buffer,
            file_name=excel_name,
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            key="download_entradas_excel",
        )

    st.subheader("Vista previa de datos")
    preview_df = create_preview_dataframe_entradas(entradas_data)
    st.dataframe(preview_df, width='stretch')


def display_salida_report_results(salidas_data, pdf_buffer, excel_buffer, pdf_name, excel_name):
    """
    Muestra los botones de descarga (PDF y Excel) y la vista previa de datos de salidas.
    """
    st.success(f"Se encontraron {len(salidas_data)} registros de salida")

    col1, col2 = st.columns(2)
    with col1:
        st.download_button(
            label="📄 Descargar PDF",
            data=pdf_buffer,
            file_name=pdf_name,
            mime="application/pdf",
            key="download_salidas_pdf",
        )
    with col2:
        st.download_button(
            label="📊 Descargar Excel",
            data=excel_buffer,
            file_name=excel_name,
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            key="download_salidas_excel",
        )

    st.subheader("Vista previa de datos")
    preview_df = create_preview_dataframe_salidas(salidas_data)
    st.dataframe(preview_df, width='stretch')


# =============================================================================
# FUNCIONES PRINCIPALES DE PÁGINA
# =============================================================================

def reporte_entradas_main(
    fecha_inicio_str,
    fecha_fin_str,
    cc_selected,
    fecha_inicio,
    fecha_fin,
    can_generate,
):
    """
    Función principal del reporte de entradas.
    Muestra filtros de fecha/CC, genera el PDF y ofrece descarga.
    """
    st.title("📄 Reporte de Entradas")
    
    st.info(
        "Este reporte extrae las entradas registradas de la base de datos, "
        "mostrando fecha, centro de costos, materiales, cantidades y precios."
    )

    if st.button("Generar Reporte de Entradas", key="entradas_pdf", disabled=not can_generate):
        with st.spinner("Obteniendo datos de entradas..."):
            try:
                entradas_data = get_entradas_data(
                    fecha_inicio_str, fecha_fin_str, cc_selected=cc_selected
                )
            except Exception as e:
                st.error(f"Error al obtener datos: {e}")
                return

        if entradas_data:
            pdf_buffer = create_entradas_pdf(entradas_data)
            excel_buffer = create_entradas_excel(entradas_data)
            pdf_name = build_report_filename(
                "entradas", fecha_inicio, fecha_fin, cc_selected, "pdf"
            )
            excel_name = build_report_filename(
                "entradas", fecha_inicio, fecha_fin, cc_selected, "xlsx"
            )
            display_report_results(entradas_data, pdf_buffer, excel_buffer, pdf_name, excel_name)
        else:
            st.warning(
                "No se encontraron registros de entrada en el rango de fechas especificado."
            )


def reporte_salidas_main(
    fecha_inicio_str,
    fecha_fin_str,
    cc_selected,
    fecha_inicio,
    fecha_fin,
    can_generate,
):
    """
    Función principal del reporte de salidas.
    Muestra filtros de fecha/CC, genera el PDF y ofrece descarga.
    """
    st.title("📄 Reporte de Salidas")
    
    st.info(
        "Este reporte extrae las salidas registradas de la base de datos, "
        "mostrando fecha, centro de costos, materiales y detalles."
    )

    if st.button("Generar Reporte de Salidas", key="salidas_pdf", disabled=not can_generate):
        with st.spinner("Obteniendo datos de salidas..."):
            try:
                salidas_data = get_salidas_data(
                    fecha_inicio_str, fecha_fin_str, cc_selected=cc_selected
                )
            except Exception as e:
                st.error(f"Error al obtener datos: {e}")
                return

        if salidas_data:
            pdf_buffer = create_salidas_pdf(salidas_data)
            excel_buffer = create_salidas_excel(salidas_data)
            pdf_name = build_report_filename(
                "salidas", fecha_inicio, fecha_fin, cc_selected, "pdf"
            )
            excel_name = build_report_filename(
                "salidas", fecha_inicio, fecha_fin, cc_selected, "xlsx"
            )
            display_salida_report_results(salidas_data, pdf_buffer, excel_buffer, pdf_name, excel_name)
        else:
            st.warning(
                "No se encontraron registros de salida en el rango de fechas especificado."
            )


def reporte_comparacion_main(
    fecha_inicio_str,
    fecha_fin_str,
    cc_selected,
    fecha_inicio,
    fecha_fin,
    can_generate,
):
    """
    Función principal del reporte comparativo entradas vs salidas.
    Muestra filtros de fecha/CC, genera el PDF y ofrece descarga.
    """
    st.title("📊 Reporte Comparativo")
    st.subheader("Entradas vs Salidas por Centro de Costo")
    st.info(
        "Este reporte compara los materiales y herramientas que entraron "
        "contra los que salieron para un mismo centro de costos, "
        "mostrando el porcentaje de uso real."
    )

    if st.button("Generar Reporte Comparativo", key="comparacion_pdf", disabled=not can_generate):
        with st.spinner("Obteniendo datos comparativos..."):
            try:
                comparacion_data = get_comparacion_data(
                    fecha_inicio_str, fecha_fin_str, cc_selected=cc_selected
                )
            except Exception as e:
                st.error(f"Error al obtener datos para comparar : {e}")
                return

        if comparacion_data:
            pdf_buffer = create_comparacion_pdf(comparacion_data)
            excel_buffer = create_comparacion_excel(comparacion_data)
            pdf_name = build_report_filename(
                "comparativo", fecha_inicio, fecha_fin, cc_selected, "pdf"
            )
            excel_name = build_report_filename(
                "comparativo", fecha_inicio, fecha_fin, cc_selected, "xlsx"
            )

            st.success(
                f"Se encontraron {len(comparacion_data)} materiales/herramientas para comparar"
            )

            col1, col2 = st.columns(2)
            with col1:
                st.download_button(
                    label="📄 Descargar PDF",
                    data=pdf_buffer,
                    file_name=pdf_name,
                    mime="application/pdf",
                    key="download_comparacion_pdf",
                )
            with col2:
                st.download_button(
                    label="📊 Descargar Excel",
                    data=excel_buffer,
                    file_name=excel_name,
                    mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    key="download_comparacion_excel",
                )

            st.subheader("Vista previa de datos")
            preview_df = pd.DataFrame(comparacion_data)
            preview_df.columns = [
                "C.C", "Material", "Tipo", "Unidad", "Precio Unit.",
                "Total Entradas", "Total Salidas",
                "Usado", "Costo material usado",
            ]
            st.dataframe(preview_df, width='stretch')

            total_costo = sum(i["costo_material_usado"] for i in comparacion_data)
            st.metric("Costo Total de material usado", f"${total_costo:,.2f}")
        else:
            st.warning(
                "No se encontraron registros en el rango de fechas especificado."
            )

def main():
    key_prefix_map = {
        "Entradas": "entradas_",
        "Salidas": "salidas_",
        "Comparativo": "comparacion_",
    }
    col1, col2 = st.columns([1, 2])
    with col1:

        tipo_reporte = st.selectbox(
        "Selecciona el tipo de reporte",
        options=["Entradas", "Salidas", "Comparativo"],
        key="tipo_reporte_selector",
        )
    with col2:
        ccs = get_all_cc()

        cc_selected = st.selectbox(
        "Centro de Costos (CC)",
        options=ccs,
        index=None,
        placeholder="Selecciona un CC...",
        key=f"{key_prefix_map[tipo_reporte]}cc_selected",
    )
    

    (
        fecha_inicio_str,
        fecha_fin_str,
        fecha_inicio,
        fecha_fin,
    ) = render_filter_section(key_prefix=key_prefix_map[tipo_reporte])

    can_generate = bool(cc_selected)
    if not can_generate:
        st.warning("Debes seleccionar un Centro de Costos para generar el reporte.")

    if tipo_reporte == "Entradas":
        reporte_entradas_main(
            fecha_inicio_str,
            fecha_fin_str,
            cc_selected,
            fecha_inicio,
            fecha_fin,
            can_generate,
        )
    elif tipo_reporte == "Salidas":
        reporte_salidas_main(
            fecha_inicio_str,
            fecha_fin_str,
            cc_selected,
            fecha_inicio,
            fecha_fin,
            can_generate,
        )
    elif tipo_reporte == "Comparativo":
        reporte_comparacion_main(
            fecha_inicio_str,
            fecha_fin_str,
            cc_selected,
            fecha_inicio,
            fecha_fin,
            can_generate,
        )