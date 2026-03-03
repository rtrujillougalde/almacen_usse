import streamlit as st
from reportlab.lib.pagesizes import letter, A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from io import BytesIO
import datetime
import pandas as pd
from sqlalchemy.orm import sessionmaker
from sqlalchemy import and_
from classes import Articulos, Movimientos, DetalleMovimiento, Proyectos
from utils import get_engine, get_session


def get_all_cc():
    """
    Obtiene todos los centros de costo (CC) únicos de la base de datos.
    
    Returns:
        list: Lista de centros de costo
    """
    try:
        session = get_session()
        ccs = session.query(Proyectos.c_c).distinct().all()
        session.close()
        return sorted([cc[0] for cc in ccs if cc[0] is not None])
    except Exception as e:
        st.error(f"Error al obtener centros de costo: {e}")
        return []


def get_entradas_data(fecha_inicio=None, fecha_fin=None, cc_filter=None):
    """
    Obtiene datos de entradas desde la base de datos.
    
    Args:
        fecha_inicio (str): Fecha de inicio (formato YYYY-MM-DD)
        fecha_fin (str): Fecha de fin (formato YYYY-MM-DD)
        cc_filter (int or list): Centro de costo a filtrar, puede ser un int o lista de ints
    
    Returns:
        list: Lista de tuplas con datos de entradas
    """
    try:
        session = get_session()
        
        # Consulta para obtener entradas
        query = session.query(
            Movimientos.fecha_hora,
            Proyectos.c_c,
            Articulos.nombre,
            DetalleMovimiento.cantidad,
            Articulos.precio_unitario,
            Movimientos.observaciones
        ).join(
            DetalleMovimiento, Movimientos.id_movimiento == DetalleMovimiento.id_movimiento
        ).join(
            Articulos, DetalleMovimiento.id_articulo == Articulos.id_articulo
        ).join(
            Proyectos, Movimientos.id_proyecto == Proyectos.id_proyecto
        ).filter(
            Movimientos.tipo == "entrada"
        )
        
        # Aplicar filtros de fecha si se proporcionan
        if fecha_inicio and fecha_fin:
            # Usar CAST para comparar solo la fecha, ignorando la hora
            from sqlalchemy import func, cast, Date
            query = query.filter(
                and_(
                    cast(Movimientos.fecha_hora, Date) >= fecha_inicio,
                    cast(Movimientos.fecha_hora, Date) <= fecha_fin
                )
            )
        
        # Aplicar filtro de CC si se proporciona
        if cc_filter is not None:
            if isinstance(cc_filter, list):
                query = query.filter(Proyectos.c_c.in_(cc_filter))
            else:
                query = query.filter(Proyectos.c_c == cc_filter)
        
        entradas = query.order_by(Movimientos.fecha_hora.desc()).all()
        session.close()
        
        # Debug: mostrar información de la consulta
        
        st.write(f"Registros encontrados: {len(entradas)}")
        
        return entradas
    
    except Exception as e:
        st.error(f"Error al obtener datos de entradas: {e}")
        import traceback
        st.error(traceback.format_exc())
        return []


def create_entradas_pdf(entradas_data):
    """
    Crea un PDF con datos de entradas.
    
    Args:
        entradas_data (list): Lista de tuplas con datos de entradas
    """
    buffer = BytesIO()
    
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=50,
        leftMargin=50,
        topMargin=72,
        bottomMargin=18,
    )
    
    elements = []
    styles = getSampleStyleSheet()
    
    # Título
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=22,
        textColor=colors.HexColor('#1f77b4'),
        spaceAfter=20,
        alignment=1
    )
    elements.append(Paragraph("Reporte de Entradas de Almacén", title_style))
    elements.append(Spacer(1, 0.2*inch))
    
    # Fecha de generación
    elements.append(Paragraph(
        f"<b>Fecha de Generación:</b> {datetime.datetime.now().strftime('%d/%m/%Y %H:%M:%S')}", 
        styles['Normal']
    ))
    elements.append(Spacer(1, 0.3*inch))
    
    # Tabla de entradas
    if entradas_data:
        # Preparar datos para la tabla
        table_data = [[
            'Fecha/Hora',
            'C.C',
            'Material',
            'Cantidad',
            'Precio Unit.',
            'Total'
        ]]
        
        total_general = 0
        
        for entrada in entradas_data:
            fecha_hora, cc, material, cantidad, precio_unitario, observaciones = entrada
            total = cantidad * (precio_unitario or 0)
            total_general += total
            
            table_data.append([
                str(fecha_hora)[:19],  # Limitar a date/time sin milisegundos
                str(cc),
                material[:30],  # Limitar longitud del material
                str(cantidad),
                f"${precio_unitario:.2f}" if precio_unitario else "$0.00",
                f"${total:.2f}"
            ])
        
        # Crear tabla
        table = Table(table_data, colWidths=[1.2*inch, 0.6*inch, 1.5*inch, 0.8*inch, 1*inch, 1*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1f77b4')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('FONTSIZE', (0, 1), (-1, -1), 9),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f0f0f0')]),
        ]))
        
        elements.append(table)
        elements.append(Spacer(1, 0.3*inch))
        
        # Total general
        total_style = ParagraphStyle(
            'TotalStyle',
            parent=styles['Normal'],
            fontSize=12,
            textColor=colors.HexColor('#1f77b4'),
            alignment=2  # Derecha
        )
        elements.append(Paragraph(f"<b>TOTAL GENERAL:</b> ${total_general:,.2f}", total_style))
    
    else:
        elements.append(Paragraph("No hay datos de entradas para mostrar.", styles['Normal']))
    
    # Construir el PDF
    doc.build(elements)
    buffer.seek(0)
    return buffer


def main():
    st.set_page_config(page_title="Reporte de Entradas - Almacén USSE")
    st.title("📄 Reporte de Entradas - Almacén USSE")
    st.subheader("Reporte de Entradas de Almacén")
    st.info("Este reporte extrae las entradas registradas de la base de datos, mostrando fecha, centro de costos, materiales, cantidades y precios.")
    
    # Obtener lista de centros de costo
    ccs = get_all_cc()
    
    col1, col2, col3 = st.columns(3)
    
    with col1:
        fecha_inicio = st.date_input(
            "Fecha de inicio",
            value=datetime.date(datetime.datetime.now().year, 1, 1)
        )
    
    with col2:
        fecha_fin = st.date_input(
            "Fecha de fin",
            value=datetime.date.today()
        )
    
    with col3:
        cc_seleccionados = st.multiselect(
            "Centro de Costos (CC)",
            options=ccs,
            default=None,
            help="Selecciona uno o varios CC. Si no seleccionas ninguno, se mostrarán todos."
        )
    
    if st.button("Generar Reporte de Entradas", key="entradas_pdf"):
        # Convertir fechas al formato requerido
        fecha_inicio_str = fecha_inicio.strftime("%Y-%m-%d")
        fecha_fin_str = fecha_fin.strftime("%Y-%m-%d")
        
        # Obtener datos de entradas
        with st.spinner("Obteniendo datos de entradas..."):
            entradas_data = get_entradas_data(
                fecha_inicio_str, 
                fecha_fin_str,
                cc_filter=cc_seleccionados if cc_seleccionados else None
            )
        
        if entradas_data:
            st.success(f"Se encontraron {len(entradas_data)} registros de entrada")
            
            # Generar PDF
            pdf_buffer = create_entradas_pdf(entradas_data)
            
            # Construir nombre del archivo
            cc_str = f"_cc_{'_'.join(map(str, cc_seleccionados))}" if cc_seleccionados else ""
            file_name = f"reporte_entradas_{fecha_inicio.strftime('%d%m%Y')}_a_{fecha_fin.strftime('%d%m%Y')}{cc_str}.pdf"
            
            st.download_button(
                label="⬇️ Descargar Reporte de Entradas",
                data=pdf_buffer,
                file_name=file_name,
                mime="application/pdf",
                key="download_entradas"
            )
            
            # Mostrar preview en Streamlit
            st.subheader("Vista previa de datos")
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
                    "Total": f"${total:.2f}"
                })
            
            st.dataframe(pd.DataFrame(preview_df), use_container_width=True)
        
        else:
            st.warning("No se encontraron registros de entrada en el rango de fechas especificado.")


