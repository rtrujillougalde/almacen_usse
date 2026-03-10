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
    create_entradas_pdf,
    create_salidas_pdf,
)


# =============================================================================
# HELPERS DE UI
# =============================================================================

def render_filter_section(key_prefix=""):
    """
    Renderiza la sección de filtros (fechas y centro de costo) y devuelve
    los valores seleccionados.

    Args:
        key_prefix (str): Prefijo para las claves de los widgets (evita conflictos).

    Returns:
        tuple: (fecha_inicio_str, fecha_fin_str, cc_filter,
                fecha_inicio, fecha_fin, cc_seleccionados)
    """
    ccs = get_all_cc()

    col1, col2, col3 = st.columns(3)

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

    with col3:
        cc_seleccionados = st.multiselect(
            "Centro de Costos (CC)",
            options=ccs,
            default=None,
            help="Selecciona uno o varios CC. Si no seleccionas ninguno, se mostrarán todos.",
            key=f"{key_prefix}cc_filter",
        )

    fecha_inicio_str = fecha_inicio.strftime("%Y-%m-%d")
    fecha_fin_str = fecha_fin.strftime("%Y-%m-%d")
    cc_filter = cc_seleccionados if cc_seleccionados else None

    return (
        fecha_inicio_str,
        fecha_fin_str,
        cc_filter,
        fecha_inicio,
        fecha_fin,
        cc_seleccionados,
    )


def build_pdf_filename(report_type, fecha_inicio, fecha_fin, cc_seleccionados):
    """
    Construye el nombre del archivo PDF con el rango de fechas y centros de costo.

    Args:
        report_type (str): Tipo de reporte ('entradas' o 'salidas').
        fecha_inicio: Objeto date de inicio.
        fecha_fin: Objeto date de fin.
        cc_seleccionados (list): Lista de centros de costo seleccionados.

    Returns:
        str: Nombre del archivo formateado.
    """
    cc_str = (
        f"_cc_{'_'.join(map(str, cc_seleccionados))}" if cc_seleccionados else ""
    )
    return (
        f"reporte_{report_type}_{fecha_inicio.strftime('%d%m%Y')}"
        f"_a_{fecha_fin.strftime('%d%m%Y')}{cc_str}.pdf"
    )


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
            detalle = f"{cantidad} unidades"

        preview_df.append({
            "Fecha/Hora": fecha_hora,
            "C.C": cc,
            "Material": material,
            "Cantidad": cantidad if not nombre_punta else "Punta",
            "Detalle": detalle,
        })
    return pd.DataFrame(preview_df)


def display_report_results(entradas_data, pdf_buffer, file_name):
    """
    Muestra el botón de descarga del PDF y la vista previa de datos de entradas.

    Args:
        entradas_data (list[tuple]): Datos de entradas.
        pdf_buffer (BytesIO): Buffer con el contenido del PDF.
        file_name (str): Nombre para el archivo PDF descargable.
    """
    st.success(f"Se encontraron {len(entradas_data)} registros de entrada")

    st.download_button(
        label="⬇️ Descargar Reporte de Entradas",
        data=pdf_buffer,
        file_name=file_name,
        mime="application/pdf",
        key="download_entradas",
    )

    st.subheader("Vista previa de datos")
    preview_df = create_preview_dataframe_entradas(entradas_data)
    st.dataframe(preview_df, use_container_width=True)


def display_salida_report_results(salidas_data, pdf_buffer, file_name):
    """
    Muestra el botón de descarga del PDF y la vista previa de datos de salidas.

    Args:
        salidas_data (list[tuple]): Datos de salidas.
        pdf_buffer (BytesIO): Buffer con el contenido del PDF.
        file_name (str): Nombre para el archivo PDF descargable.
    """
    st.success(f"Se encontraron {len(salidas_data)} registros de salida")

    st.download_button(
        label="⬇️ Descargar Reporte de Salidas",
        data=pdf_buffer,
        file_name=file_name,
        mime="application/pdf",
        key="download_salidas",
    )

    st.subheader("Vista previa de datos")
    preview_df = create_preview_dataframe_salidas(salidas_data)
    st.dataframe(preview_df, use_container_width=True)


# =============================================================================
# FUNCIONES PRINCIPALES DE PÁGINA
# =============================================================================

def main():
    """
    Función principal del reporte de entradas.
    Muestra filtros de fecha/CC, genera el PDF y ofrece descarga.
    """
    st.title("📄 Reporte de Entradas - Almacén USSE")
    st.subheader("Reporte de Entradas de Almacén")
    st.info(
        "Este reporte extrae las entradas registradas de la base de datos, "
        "mostrando fecha, centro de costos, materiales, cantidades y precios."
    )

    (
        fecha_inicio_str,
        fecha_fin_str,
        cc_filter,
        fecha_inicio,
        fecha_fin,
        cc_seleccionados,
    ) = render_filter_section(key_prefix="entradas_")

    if st.button("Generar Reporte de Entradas", key="entradas_pdf"):
        with st.spinner("Obteniendo datos de entradas..."):
            try:
                entradas_data = get_entradas_data(
                    fecha_inicio_str, fecha_fin_str, cc_filter=cc_filter
                )
            except Exception as e:
                st.error(f"Error al obtener datos: {e}")
                return

        if entradas_data:
            pdf_buffer = create_entradas_pdf(entradas_data)
            file_name = build_pdf_filename(
                "entradas", fecha_inicio, fecha_fin, cc_seleccionados
            )
            display_report_results(entradas_data, pdf_buffer, file_name)
        else:
            st.warning(
                "No se encontraron registros de entrada en el rango de fechas especificado."
            )


def reporte_salidas_main():
    """
    Función principal del reporte de salidas.
    Muestra filtros de fecha/CC, genera el PDF y ofrece descarga.
    """
    st.title("📄 Reporte de Salidas - Almacén USSE")
    st.subheader("Reporte de Salidas de Almacén")
    st.info(
        "Este reporte extrae las salidas registradas de la base de datos, "
        "mostrando fecha, centro de costos, materiales y detalles."
    )

    (
        fecha_inicio_str,
        fecha_fin_str,
        cc_filter,
        fecha_inicio,
        fecha_fin,
        cc_seleccionados,
    ) = render_filter_section(key_prefix="salidas_")

    if st.button("Generar Reporte de Salidas", key="salidas_pdf"):
        fecha_inicio_str = fecha_inicio.strftime("%Y-%m-%d")
        fecha_fin_str = fecha_fin.strftime("%Y-%m-%d")
        cc_filter = cc_seleccionados if cc_seleccionados else None

        with st.spinner("Obteniendo datos de salidas..."):
            try:
                salidas_data = get_salidas_data(
                    fecha_inicio_str, fecha_fin_str, cc_filter=cc_filter
                )
            except Exception as e:
                st.error(f"Error al obtener datos: {e}")
                return

        if salidas_data:
            pdf_buffer = create_salidas_pdf(salidas_data)
            file_name = build_pdf_filename(
                "salidas", fecha_inicio, fecha_fin, cc_seleccionados
            )
            display_salida_report_results(salidas_data, pdf_buffer, file_name)
        else:
            st.warning(
                "No se encontraron registros de salida en el rango de fechas especificado."
            )


