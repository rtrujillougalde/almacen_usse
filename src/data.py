"""
data.py - Capa de acceso a datos (Data Access Layer)

Contiene todas las funciones que interactúan con la base de datos MySQL
usando SQLAlchemy. No contiene llamadas a Streamlit.
Todas las funciones de consulta y manipulación de datos están centralizadas aquí.
"""
import streamlit as st  # Solo para manejo de caché, no para UI
from datetime import datetime
from io import BytesIO

import pandas as pd
from sqlalchemy import and_, cast, Date, func
from sqlalchemy.orm import sessionmaker

from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

from classes import (
    Articulos,
    DetalleMovimiento,
    Movimientos,
    Proyectos,
    StockPuntas,
)
from utils import get_session


def clear_cached_reference_data():
    """Limpia caches de lectura afectados por escrituras de inventario."""
    get_all_articulos.clear()
    get_all_articulo_names.clear()
    get_cable_names.clear()
    get_available_cable_puntas.clear()
    get_available_puntas_for_article.clear()
    get_proyectos_info.clear()


# =============================================================================
# ARTÍCULOS
# =============================================================================
@st.cache_data(ttl=300)  # Cachear por 5 minutos para mejorar rendimiento
def get_all_articulos():
    """
    Obtiene todos los artículos de la base de datos.

    Returns:
        list[dict]: Lista de diccionarios con los datos de cada artículo.
    """
    session = get_session()
    try:
        articulos = session.query(Articulos).all()
        data = [
            {
                "id": a.id_articulo,
                "nombre": a.nombre,
                "num_catalogo": a.num_catalogo,
                "cantidad en stock": round(a.cantidad_en_stock, 2) if a.cantidad_en_stock is not None else 0.00,
                "unidad de medida": a.unidad_medida,
                "stock minimo": round(a.stock_minimo, 2) if a.stock_minimo is not None else 0.00,
                "categoria": a.categoria.value if a.categoria else None,
            }
            for a in articulos
        ]
        return data
    except Exception as e:
        print(f"Error al obtener artículos: {e}")
        return []

    finally:
        session.close()

@st.cache_data(ttl=300)
def get_all_articulo_names():
    """
    Obtiene los nombres de todos los artículos.

    Returns:
        list[str]: Lista de nombres de artículos.
    """
    session = get_session()
    try:
        return [row.nombre for row in session.query(Articulos).all()]
    except Exception as e:
        print(f"Error al obtener nombres de artículos: {e}")
        return []
    
    finally:
        session.close()

@st.cache_data(ttl=300)
def get_cable_names():
    """
    Obtiene los nombres de todos los artículos que son cables.

    Returns:
        list[str]: Lista de nombres de artículos tipo cable.
    """
    session = get_session()
    try:
        cables = session.query(Articulos).filter(Articulos.es_cable == True).all()
        return [row.nombre for row in cables]
    except Exception as e:
        print(f"Error al obtener nombres de cables: {e}")
        return []
    finally:
        session.close()


def get_article_by_name(nombre):
    """
    Busca un artículo por su nombre.

    Args:
        nombre (str): Nombre del artículo.

    Returns:
        Articulos | None: Objeto artículo o None si no existe.
    """
    session = get_session()
    try:
        return session.query(Articulos).filter(Articulos.nombre == nombre).first()
    except Exception as e:
        print(f"Error al buscar artículo por nombre '{nombre}': {e}")
        return None
    finally:
        session.close()


def get_article_by_id(id_articulo):
    """
    Busca un artículo por su ID.

    Args:
        id_articulo (int): ID del artículo.

    Returns:
        Articulos | None: Objeto artículo o None si no existe.
    """
    session = get_session()
    try:
        return session.query(Articulos).filter(
            Articulos.id_articulo == id_articulo
        ).first()
    finally:
        session.close()


def update_articulo(id_articulo, nombre, num_catalogo, cantidad_en_stock, unidad_medida, stock_minimo):
    """
    Actualiza los campos editables de un artículo.

    Args:
        id_articulo (int): ID del artículo a actualizar.
        nombre (str): Nuevo nombre.
        cantidad_en_stock (int): Nueva cantidad en stock.
        unidad_medida (str): Nueva unidad de medida.
        stock_minimo (float): Nuevo stock mínimo.

    Raises:
        ValueError: Si el artículo no existe.
        Exception: Si ocurre un error en la base de datos.
    """
    session = get_session()
    try:
        articulo = session.query(Articulos).filter(
            Articulos.id_articulo == id_articulo
        ).first()
        if not articulo:
            raise ValueError(f"Artículo con ID {id_articulo} no encontrado")
        articulo.nombre = nombre
        articulo.num_catalogo = num_catalogo
        articulo.cantidad_en_stock = cantidad_en_stock
        articulo.unidad_medida = unidad_medida
        articulo.stock_minimo = stock_minimo
        session.commit()
    except Exception as e:
        session.rollback()
        print(f"Error al actualizar artículo ID {id_articulo}: {e}")
        
        raise
    finally:
        session.close()


# =============================================================================
# CABLES / PUNTAS
# =============================================================================
def _query_available_puntas(session, *, id_articulo=None, cable_name=None):
    """Obtiene puntas disponibles aplicando el filtro en SQL, no en Python."""
    used_puntas_subquery = session.query(DetalleMovimiento.id_punta).join(
        Movimientos, DetalleMovimiento.id_movimiento == Movimientos.id_movimiento
    ).filter(
        Movimientos.tipo == "salida",
        DetalleMovimiento.id_punta.isnot(None),
    ).distinct()

    query = session.query(
        StockPuntas.id_punta,
        StockPuntas.nombre_punta,
        StockPuntas.longitud,
    ).filter(
        ~StockPuntas.id_punta.in_(used_puntas_subquery)
    )

    if id_articulo is not None:
        query = query.filter(StockPuntas.id_articulo == id_articulo)

    if cable_name is not None:
        query = query.join(
            Articulos, StockPuntas.id_articulo == Articulos.id_articulo
        ).filter(Articulos.nombre == cable_name)

    return [
        {
            "id_punta": row.id_punta,
            "nombre_punta": row.nombre_punta,
            "longitud": row.longitud,
        }
        for row in query.order_by(StockPuntas.id_punta).all()
    ]


@st.cache_data(ttl=300)
def get_available_cable_puntas(cable_name):
    """
    Obtiene las puntas disponibles de un cable, excluyendo las que ya tienen salida.

    Args:
        cable_name (str): Nombre del cable.

    Returns:
        list[dict]: Lista de diccionarios con 'nombre de punta' y 'longitud'.
    """
    session = get_session()
    try:
        puntas = _query_available_puntas(session, cable_name=cable_name)
        return [
            {
                "nombre de punta": punta["nombre_punta"],
                "longitud": punta["longitud"],
            }
            for punta in puntas
        ]
    finally:
        session.close()


@st.cache_data(ttl=300)
def get_available_puntas_for_article(id_articulo: int):
    """
    Obtiene las puntas disponibles para un artículo cable,
    excluyendo las que ya fueron utilizadas en movimientos de salida.

    Args:
        id_articulo (int): ID del artículo cable.

    Returns:
        list[StockPuntas]: Lista de objetos StockPuntas disponibles.
    """
    session = get_session()
    try:
        return _query_available_puntas(session, id_articulo=id_articulo)
    finally:
        session.close()


def get_punta_by_id(id_punta: int):
    """
    Busca una punta por su ID.

    Args:
        id_punta (int): ID de la punta.

    Returns:
        StockPuntas | None: Objeto punta o None.
    """
    session = get_session()
    try:
        return session.query(StockPuntas).filter(
            StockPuntas.id_punta == id_punta
        ).first()
    finally:
        session.close()


def get_cables_without_salida():
    """
    Obtiene nombres de puntas de cable que no tienen movimiento de salida.

    Returns:
        list[str]: Lista de nombres de puntas disponibles.
    """
    session = get_session()
    try:
        puntas_with_salida = session.query(DetalleMovimiento.id_punta).join(
            Movimientos, DetalleMovimiento.id_movimiento == Movimientos.id_movimiento
        ).filter(Movimientos.tipo == "salida").distinct().all()
        salida_punta_ids = {row.id_punta for row in puntas_with_salida}

        cable_puntas = session.query(StockPuntas).join(
            Articulos, StockPuntas.id_articulo == Articulos.id_articulo
        ).filter(Articulos.es_cable == 1).all()

        return [
            punta.nombre_punta
            for punta in cable_puntas
            if punta.id_punta not in salida_punta_ids
        ]
    finally:
        session.close()


# =============================================================================
# PROYECTOS
# =============================================================================

def get_all_proyectos():
    """
    Obtiene todos los proyectos de la base de datos.

    Returns:
        list[Proyectos]: Lista de objetos Proyectos.
    """
    session = get_session()
    try:
        return session.query(Proyectos).all()
    finally:
        session.close()


@st.cache_data(ttl=300)
def get_proyectos_info():
    """
    Obtiene un diccionario con la información de todos los proyectos.

    Returns:
        dict: {id_proyecto: (nombre_obra, c_c)}
    """
    session = get_session()
    try:
        proyectos = session.query(Proyectos).all()
        return {
            p.id_proyecto: (p.nombre_obra, p.c_c)
            for p in proyectos
        }
    finally:
        session.close()


def add_proyecto(c_c, nombre_obra, encargado):
    """
    Agrega un nuevo proyecto a la base de datos.

    Args:
        c_c (int): Centro de costo.
        nombre_obra (str): Nombre de la obra.
        encargado (str): Encargado del proyecto.

    Returns:
        Proyectos: El proyecto creado.

    Raises:
        Exception: Si ocurre un error en la base de datos.
    """
    session = get_session()
    try:
        nuevo_proyecto = Proyectos(
            c_c=c_c, nombre_obra=nombre_obra, encargado=encargado
        )
        session.add(nuevo_proyecto)
        session.commit()
        return nuevo_proyecto
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def get_all_cc():
    """
    Obtiene todos los centros de costo (CC) únicos de los proyectos.

    Returns:
        list[int]: Lista ordenada de centros de costo.
    """
    session = get_session()
    try:
        ccs = session.query(Proyectos.c_c).distinct().all()
        return sorted([cc[0] for cc in ccs if cc[0] is not None])
    finally:
        session.close()


# =============================================================================
# MOVIMIENTOS - ENTRADAS
# =============================================================================

def fetch_initial_data():
    """
    Obtiene los datos iniciales necesarios para el formulario de entradas:
    nombres de artículos, nombres de cables y info de proyectos.

    Returns:
        tuple: (nombres_articulos, nombres_cables, proyectos_info)

    Raises:
        Exception: Si ocurre un error al consultar la base de datos.
    """
    nombres_articulos = get_all_articulo_names()
    nombres_cables = get_cable_names()
    proyectos_info = get_proyectos_info()
    return nombres_articulos, nombres_cables, proyectos_info


def add_movement_to_db(movement_items, id_proyecto, responsable):
    """
    Crea un registro de Movimiento tipo 'entrada' y agrega los DetalleMovimiento
    correspondientes. Actualiza el stock de los artículos.

    Args:
        movement_items (list[dict]): Lista de diccionarios con los datos de cada ítem.
            Cada dict contiene: is_new, nombre_item, tipo, precio_unitario,
            unidad_medida, categoria, stock_minimo, es_cable, nombre_punta,
            longitud, cantidad.
        id_proyecto (int, optional): ID del proyecto asociado al movimiento.
        responsable (str, optional): Nombre del responsable de la entrada.

    Returns:
        bool: True si se registró exitosamente.

    Raises:
        Exception: Si ocurre un error en la base de datos.
    """
    session = get_session()
    try:
        movimiento = Movimientos(
            id_proyecto=id_proyecto,
            tipo="entrada",
            fecha_hora=datetime.now().isoformat(),
            observaciones="",
            responsable=responsable,
        )
        session.add(movimiento)
        session.flush()

        existing_names = {
            item["nombre_item"]
            for item in movement_items
            if not item["is_new"]
        }
        existing_articles = {}
        if existing_names:
            existing_articles = {
                articulo.nombre: articulo
                for articulo in session.query(Articulos).filter(
                    Articulos.nombre.in_(existing_names)
                ).all()
            }

        for item_data in movement_items:
            nueva_punta = None

            if item_data["is_new"]:
                articulo = Articulos(
                    nombre=item_data["nombre_item"],
                    tipo=item_data["tipo"],
                    precio_unitario=item_data["precio_unitario"],
                    unidad_medida=item_data["unidad_medida"],
                    categoria=item_data["categoria"],
                    stock_minimo=item_data["stock_minimo"],
                    es_cable=True if item_data["es_cable"] else False,
                    cantidad_en_stock=(
                        item_data["cantidad"]
                        if not item_data["es_cable"]
                        else item_data["longitud"]
                    ),
                )
                session.add(articulo)
                session.flush()

                if item_data["es_cable"]:
                    nueva_punta = StockPuntas(
                        id_articulo=articulo.id_articulo,
                        nombre_punta=item_data["nombre_punta"],
                        longitud=item_data["longitud"],
                    )
                    session.add(nueva_punta)
                    session.flush()
            else:
                articulo = existing_articles.get(item_data["nombre_item"])
                if not articulo:
                    raise ValueError(
                        f"Artículo no encontrado: {item_data['nombre_item']}"
                    )

                if item_data["es_cable"]:
                    nueva_punta = StockPuntas(
                        id_articulo=articulo.id_articulo,
                        nombre_punta=item_data["nombre_punta"],
                        longitud=item_data["longitud"],
                    )
                    session.add(nueva_punta)
                    articulo.cantidad_en_stock += item_data["longitud"]
                else:
                    articulo.cantidad_en_stock += item_data["cantidad"]

            detalle = DetalleMovimiento(
                id_movimiento=movimiento.id_movimiento,
                id_articulo=articulo.id_articulo,
                cantidad=(
                    item_data["cantidad"]
                    if not item_data["es_cable"]
                    else item_data["longitud"]
                ),
                id_punta=nueva_punta.id_punta if nueva_punta else None,
            )
            session.add(detalle)

        session.commit()
        clear_cached_reference_data()
        return True
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def get_recent_movements(tipo, limit=5):
    """
    Obtiene los movimientos más recientes de un tipo dado con sus detalles.

    Args:
        tipo (str): Tipo de movimiento ('entrada' o 'salida').
        limit (int): Cantidad máxima de movimientos a devolver.

    Returns:
        list[dict]: Lista de diccionarios con la estructura:
            {
                'id_movimiento': int,
                'fecha_hora': str,
                'id_proyecto': int,
                'items': [{'Item': str, 'Cantidad': str/int}],
                'responsable': str
            }
    """
    session = get_session()
    try:
        movimientos = session.query(Movimientos).filter(
            Movimientos.tipo == tipo
        ).order_by(Movimientos.fecha_hora.desc()).limit(limit).all()

        if not movimientos:
            return []

        movement_ids = [mov.id_movimiento for mov in movimientos]
        detalles = session.query(
            DetalleMovimiento.id_movimiento,
            DetalleMovimiento.cantidad,
            Articulos.nombre,
            Articulos.num_catalogo,
            Articulos.es_cable,
            StockPuntas.nombre_punta,
            StockPuntas.longitud,
        ).join(
            Articulos, DetalleMovimiento.id_articulo == Articulos.id_articulo
        ).outerjoin(
            StockPuntas, DetalleMovimiento.id_punta == StockPuntas.id_punta
        ).filter(
            DetalleMovimiento.id_movimiento.in_(movement_ids)
        ).order_by(
            DetalleMovimiento.id_movimiento,
            DetalleMovimiento.id_detalle,
        ).all()

        result_by_id = {}
        for mov in movimientos:
            result_by_id[mov.id_movimiento] = {
                "id_movimiento": mov.id_movimiento,
                "fecha_hora": mov.fecha_hora,
                "id_proyecto": mov.id_proyecto,
                "items": [],
                "responsable": mov.responsable,
            }

        for detalle in detalles:
            if detalle.es_cable:
                if detalle.nombre_punta:
                    item_info = f"{detalle.nombre} - {detalle.nombre_punta}"
                    cantidad = f"{detalle.longitud} m"
                else:
                    item_info = f"{detalle.nombre} (punta no encontrada)"
                    cantidad = "N/A"
            else:
                item_info = detalle.nombre
                cantidad = detalle.cantidad

            result_by_id[detalle.id_movimiento]["items"].append({
                "Item": item_info,
                "Cantidad": cantidad,
            })

        return [result_by_id[mov.id_movimiento] for mov in movimientos]
    finally:
        session.close()


# =============================================================================
# MOVIMIENTOS - SALIDAS
# =============================================================================

def add_salida_to_db(movement_items, id_proyecto=None, responsable=None):
    """
    Crea un registro de Movimiento tipo 'salida' y actualiza el stock.

    Args:
        movement_items (list[dict]): Lista de diccionarios con los datos de cada ítem.
            Cada dict contiene: id_articulo, nombre_item, es_cable, cantidad, id_punta.
        id_proyecto (int, optional): ID del proyecto asociado.
        responsable (str, optional): Nombre del responsable de la salida.

    Returns:
        bool: True si se registró exitosamente.

    Raises:
        ValueError: Si no hay stock suficiente o no se encuentra artículo/punta.
        Exception: Si ocurre un error en la base de datos.
    """
    session = get_session()
    try:
        movimiento = Movimientos(
            id_proyecto=id_proyecto,
            tipo="salida",
            fecha_hora=datetime.now().isoformat(),
            observaciones="",
            responsable=responsable,
        )
        session.add(movimiento)
        session.flush()

        article_ids = {item["id_articulo"] for item in movement_items}
        articles = {
            articulo.id_articulo: articulo
            for articulo in session.query(Articulos).filter(
                Articulos.id_articulo.in_(article_ids)
            ).all()
        }
        punta_ids = {
            item["id_punta"]
            for item in movement_items
            if item["es_cable"] and item.get("id_punta") is not None
        }
        puntas = {}
        if punta_ids:
            puntas = {
                punta.id_punta: punta
                for punta in session.query(StockPuntas).filter(
                    StockPuntas.id_punta.in_(punta_ids)
                ).all()
            }

        for item_data in movement_items:
            articulo = articles.get(item_data["id_articulo"])

            if not articulo:
                raise ValueError(
                    f"Artículo no encontrado: {item_data['nombre_item']}"
                )

            if not item_data["es_cable"]:
                if articulo.cantidad_en_stock < item_data["cantidad"]:
                    raise ValueError(
                        f"Stock insuficiente para {item_data['nombre_item']}"
                    )
                articulo.cantidad_en_stock -= item_data["cantidad"]
                cantidad_detalle = item_data["cantidad"]
                id_punta = None
            else:
                punta = puntas.get(item_data["id_punta"])

                if not punta:
                    raise ValueError("Punta no encontrada")

                if articulo.cantidad_en_stock < punta.longitud:
                    raise ValueError(
                        f"Stock insuficiente para {item_data['nombre_item']}"
                    )

                articulo.cantidad_en_stock -= punta.longitud
                cantidad_detalle = punta.longitud
                id_punta = item_data["id_punta"]

            detalle = DetalleMovimiento(
                id_movimiento=movimiento.id_movimiento,
                id_articulo=item_data["id_articulo"],
                cantidad=cantidad_detalle,
                id_punta=id_punta,
            )
            session.add(detalle)

        session.commit()
        clear_cached_reference_data()
        return True
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


# =============================================================================
# REPORTES - CONSULTAS
# =============================================================================

def get_entradas_data(fecha_inicio=None, fecha_fin=None, cc_filter=None):
    """
    Obtiene datos de entradas para generación de reportes.

    Args:
        fecha_inicio (str, optional): Fecha de inicio en formato 'YYYY-MM-DD'.
        fecha_fin (str, optional): Fecha de fin en formato 'YYYY-MM-DD'.
        cc_filter (int | list[int], optional): Centro(s) de costo a filtrar.

    Returns:
        list[tuple]: Lista de tuplas (fecha_hora, c_c, nombre, cantidad,
                     precio_unitario, observaciones).

    Raises:
        Exception: Si ocurre un error en la consulta.
    """
    session = get_session()
    try:
        query = session.query(
            Movimientos.fecha_hora,
            Proyectos.c_c,
            Articulos.nombre,
            DetalleMovimiento.cantidad,
            Articulos.precio_unitario,
            Movimientos.observaciones,
        ).join(
            DetalleMovimiento,
            Movimientos.id_movimiento == DetalleMovimiento.id_movimiento,
        ).join(
            Articulos, DetalleMovimiento.id_articulo == Articulos.id_articulo
        ).join(
            Proyectos, Movimientos.id_proyecto == Proyectos.id_proyecto
        ).filter(Movimientos.tipo == "entrada")

        # Filtros de fecha
        if fecha_inicio and fecha_fin:
            query = query.filter(
                and_(
                    cast(Movimientos.fecha_hora, Date) >= fecha_inicio,
                    cast(Movimientos.fecha_hora, Date) <= fecha_fin,
                )
            )

        # Filtro de centro de costo
        if cc_filter is not None:
            if isinstance(cc_filter, list):
                query = query.filter(Proyectos.c_c.in_(cc_filter))
            else:
                query = query.filter(Proyectos.c_c == cc_filter)

        return query.order_by(Movimientos.fecha_hora.desc()).all()
    finally:
        session.close()


def get_salidas_data(fecha_inicio=None, fecha_fin=None, cc_filter=None):
    """
    Obtiene datos de salidas para generación de reportes.

    Args:
        fecha_inicio (str, optional): Fecha de inicio en formato 'YYYY-MM-DD'.
        fecha_fin (str, optional): Fecha de fin en formato 'YYYY-MM-DD'.
        cc_filter (int | list[int], optional): Centro(s) de costo a filtrar.

    Returns:
        list[tuple]: Lista de tuplas (fecha_hora, c_c, nombre, cantidad,
                     nombre_punta, longitud, observaciones).

    Raises:
        Exception: Si ocurre un error en la consulta.
    """
    session = get_session()
    try:
        query = session.query(
            Movimientos.fecha_hora,
            Proyectos.c_c,
            Articulos.nombre,
            DetalleMovimiento.cantidad,
            StockPuntas.nombre_punta,
            StockPuntas.longitud,
            Movimientos.observaciones,
        ).join(
            DetalleMovimiento,
            Movimientos.id_movimiento == DetalleMovimiento.id_movimiento,
        ).join(
            Articulos, DetalleMovimiento.id_articulo == Articulos.id_articulo
        ).join(
            Proyectos, Movimientos.id_proyecto == Proyectos.id_proyecto
        ).outerjoin(
            StockPuntas, DetalleMovimiento.id_punta == StockPuntas.id_punta
        ).filter(Movimientos.tipo == "salida")

        # Filtros de fecha
        if fecha_inicio and fecha_fin:
            query = query.filter(
                and_(
                    cast(Movimientos.fecha_hora, Date) >= fecha_inicio,
                    cast(Movimientos.fecha_hora, Date) <= fecha_fin,
                )
            )

        # Filtro de centro de costo
        if cc_filter is not None:
            if isinstance(cc_filter, list):
                query = query.filter(Proyectos.c_c.in_(cc_filter))
            else:
                query = query.filter(Proyectos.c_c == cc_filter)

        return query.order_by(Movimientos.fecha_hora.desc()).all()
    finally:
        session.close()


# =============================================================================
# REPORTES - GENERACIÓN DE PDF
# =============================================================================

def get_comparacion_data(fecha_inicio=None, fecha_fin=None, cc_filter=None):
    """
    Obtiene datos agrupados de entradas y salidas por artículo para un centro de costo,
    permitiendo comparar cuánto entró vs cuánto salió.

    Args:
        fecha_inicio (str, optional): Fecha de inicio 'YYYY-MM-DD'.
        fecha_fin (str, optional): Fecha de fin 'YYYY-MM-DD'.
        cc_filter (int | list[int], optional): Centro(s) de costo a filtrar.

    Returns:
        list[dict]: Lista de diccionarios con campos:
            c_c, material, tipo, total_entrada, total_salida, diferencia, porcentaje_uso
    """
    session = get_session()
    try:
        date_filters = []
        if fecha_inicio and fecha_fin:
            date_filters = [
                cast(Movimientos.fecha_hora, Date) >= fecha_inicio,
                cast(Movimientos.fecha_hora, Date) <= fecha_fin,
            ]

        cc_filters = []
        if cc_filter is not None:
            if isinstance(cc_filter, list):
                cc_filters = [Proyectos.c_c.in_(cc_filter)]
            else:
                cc_filters = [Proyectos.c_c == cc_filter]

        base_query = (
            session.query(
                Proyectos.c_c,
                Articulos.nombre,
                Articulos.tipo,
                Articulos.unidad_medida,
                Articulos.precio_unitario,
                Movimientos.tipo.label("tipo_movimiento"),
                func.sum(DetalleMovimiento.cantidad).label("total_cantidad"),
            )
            .join(DetalleMovimiento, Movimientos.id_movimiento == DetalleMovimiento.id_movimiento)
            .join(Articulos, DetalleMovimiento.id_articulo == Articulos.id_articulo)
            .join(Proyectos, Movimientos.id_proyecto == Proyectos.id_proyecto)
            .filter(*date_filters, *cc_filters)
            .group_by(
                Proyectos.c_c,
                Articulos.nombre,
                Articulos.tipo,
                Articulos.unidad_medida,
                Articulos.precio_unitario,
                Movimientos.tipo,
            )
            .all()
        )

        # Agrupar resultados por (c_c, material)
        agrupado = {}
        for row in base_query:
            key = (row.c_c, row.nombre)
            if key not in agrupado:
                agrupado[key] = {
                    "c_c": row.c_c,
                    "material": row.nombre,
                    "tipo": row.tipo.value if row.tipo else "N/A",
                    "unidad_medida": row.unidad_medida or "N/A",
                    "precio_unitario": row.precio_unitario or 0.0,
                    "total_entrada": 0.0,
                    "total_salida": 0.0,
                }
            tipo_mov = row.tipo_movimiento
            if hasattr(tipo_mov, "value"):
                tipo_mov = tipo_mov.value
            if tipo_mov == "entrada":
                agrupado[key]["total_entrada"] += row.total_cantidad or 0
            elif tipo_mov == "salida":
                agrupado[key]["total_salida"] += row.total_cantidad or 0

        result = []
        for item in agrupado.values():
            item["diferencia"] = item["total_salida"] - item["total_entrada"]
            costo_base = item["total_salida"] * item["precio_unitario"]
            if item["tipo"] == "herramienta":
                item["costo_material_usado"] = round(costo_base * 0.05, 2)
            else:
                item["costo_material_usado"] = round(costo_base, 2)
            result.append(item)

        result.sort(key=lambda x: (x["c_c"], x["material"]))
        return result
    finally:
        session.close()


def create_comparacion_pdf(comparacion_data):
    """
    Genera un PDF comparativo de entradas vs salidas por centro de costo.

    Args:
        comparacion_data (list[dict]): Datos obtenidos con get_comparacion_data().

    Returns:
        BytesIO: Buffer con el contenido del PDF generado.
    """
    buffer = BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=letter,
        rightMargin=40,
        leftMargin=40,
        topMargin=72,
        bottomMargin=18,
    )

    elements = []
    styles = getSampleStyleSheet()

    # Título
    title_style = ParagraphStyle(
        "CustomTitle",
        parent=styles["Heading1"],
        fontSize=20,
        textColor=colors.HexColor("#2ca02c"),
        spaceAfter=20,
        alignment=1,
    )
    elements.append(Paragraph("Reporte Comparativo: Entradas vs Salidas", title_style))
    elements.append(Spacer(1, 0.2 * inch))

    # Fecha de generación
    elements.append(
        Paragraph(
            f"<b>Fecha de Generación:</b> {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}",
            styles["Normal"],
        )
    )
    elements.append(Spacer(1, 0.3 * inch))

    if comparacion_data:
        # Agrupar por centro de costo
        ccs = {}
        for item in comparacion_data:
            cc = item["c_c"]
            if cc not in ccs:
                ccs[cc] = []
            ccs[cc].append(item)

        for cc, items in sorted(ccs.items()):
            # Subtítulo por CC
            cc_style = ParagraphStyle(
                f"CC_{cc}",
                parent=styles["Heading2"],
                fontSize=14,
                textColor=colors.HexColor("#2ca02c"),
                spaceAfter=10,
            )
            elements.append(Paragraph(f"Centro de Costo: {cc}", cc_style))
            elements.append(Spacer(1, 0.1 * inch))

            # Tabla
            table_data = [
                ["Material", "Tipo", "Unidad", "Entradas", "Salidas", "Diferencia", "Costo Salida"]
            ]
            subtotal_cc = 0
            for item in items:
                subtotal_cc += item["costo_material_usado"]
                table_data.append([
                    item["material"][:25],
                    item["tipo"],
                    item["unidad_medida"],
                    str(item["total_entrada"]),
                    str(item["total_salida"]),
                    str(item["diferencia"]),
                    f"${item['costo_material_usado']:,.2f}",
                ])

            table = Table(
                table_data,
                colWidths=[
                    1.5 * inch, 0.8 * inch, 0.6 * inch,
                    0.8 * inch, 0.8 * inch, 0.8 * inch, 1.0 * inch,
                ],
            )
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2ca02c")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, 0), 10),
                ("BOTTOMPADDING", (0, 0), (-1, 0), 8),
                ("GRID", (0, 0), (-1, -1), 1, colors.black),
                ("FONTSIZE", (0, 1), (-1, -1), 8),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#e8f5e9")]),
            ]))
            elements.append(table)

            # Subtotal por CC
            subtotal_style = ParagraphStyle(
                f"Subtotal_{cc}",
                parent=styles["Normal"],
                fontSize=10,
                textColor=colors.HexColor("#2ca02c"),
                alignment=2,
            )
            elements.append(
                Paragraph(f"<b>Subtotal CC {cc}:</b> ${subtotal_cc:,.2f}", subtotal_style)
            )
            elements.append(Spacer(1, 0.3 * inch))

        # Resumen general
        total_entradas = sum(i["total_entrada"] for i in comparacion_data)
        total_salidas = sum(i["total_salida"] for i in comparacion_data)
        total_costo = sum(i["costo_material_usado"] for i in comparacion_data)
        summary_style = ParagraphStyle(
            "SummaryStyle",
            parent=styles["Normal"],
            fontSize=12,
            textColor=colors.HexColor("#2ca02c"),
            alignment=2,
        )
        elements.append(
            Paragraph(
                f"<b>Total Entradas:</b> {total_entradas} &nbsp; | &nbsp; "
                f"<b>Total Salidas:</b> {total_salidas} &nbsp; | &nbsp; "
                f"<b>Costo Total:</b> ${total_costo:,.2f}",
                summary_style,
            )
        )
    else:
        elements.append(
            Paragraph("No hay datos comparativos para mostrar.", styles["Normal"])
        )

    doc.build(elements)
    buffer.seek(0)
    return buffer


def create_entradas_excel(entradas_data):
    """
    Genera un archivo Excel con los datos de entradas.

    Args:
        entradas_data (list[tuple]): Datos de entradas obtenidos con get_entradas_data().

    Returns:
        BytesIO: Buffer con el contenido del Excel generado.
    """
    rows = []
    for entrada in entradas_data:
        fecha_hora, cc, material, cantidad, precio_unitario, observaciones = entrada
        total = cantidad * (precio_unitario or 0)
        rows.append({
            "Fecha/Hora": str(fecha_hora)[:19],
            "C.C": cc,
            "Material": material,
            "Cantidad": cantidad,
            "Precio Unitario": precio_unitario or 0,
            "Total": total,
        })
    df = pd.DataFrame(rows)
    buffer = BytesIO()
    with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
        df.to_excel(writer, index=False, sheet_name="Entradas")
    buffer.seek(0)
    return buffer


def create_salidas_excel(salidas_data):
    """
    Genera un archivo Excel con los datos de salidas.

    Args:
        salidas_data (list[tuple]): Datos de salidas obtenidos con get_salidas_data().

    Returns:
        BytesIO: Buffer con el contenido del Excel generado.
    """
    rows = []
    for salida in salidas_data:
        fecha_hora, cc, material, cantidad, nombre_punta, longitud, observaciones = salida
        if nombre_punta:
            detalle = f"{nombre_punta} ({longitud}m)" if longitud else nombre_punta
        else:
            detalle = f"{cantidad} unidades"
        rows.append({
            "Fecha/Hora": str(fecha_hora)[:19],
            "C.C": cc,
            "Material": material,
            "Cantidad": cantidad if not nombre_punta else "Punta",
            "Detalle": detalle,
        })
    df = pd.DataFrame(rows)
    buffer = BytesIO()
    with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
        df.to_excel(writer, index=False, sheet_name="Salidas")
    buffer.seek(0)
    return buffer


def create_comparacion_excel(comparacion_data):
    """
    Genera un archivo Excel comparativo de entradas vs salidas.

    Args:
        comparacion_data (list[dict]): Datos obtenidos con get_comparacion_data().

    Returns:
        BytesIO: Buffer con el contenido del Excel generado.
    """
    df = pd.DataFrame(comparacion_data)
    df.columns = [
        "C.C", "Material", "Tipo", "Unidad", "Precio Unitario",
        "Total Entradas", "Total Salidas",
        "Diferencia", "Costo Salida",
    ]
    buffer = BytesIO()
    with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
        df.to_excel(writer, index=False, sheet_name="Comparativo")
    buffer.seek(0)
    return buffer


def create_entradas_pdf(entradas_data):
    """
    Genera un PDF con los datos de entradas.

    Args:
        entradas_data (list[tuple]): Datos de entradas obtenidos con get_entradas_data().

    Returns:
        BytesIO: Buffer con el contenido del PDF generado.
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
        "CustomTitle",
        parent=styles["Heading1"],
        fontSize=22,
        textColor=colors.HexColor("#1f77b4"),
        spaceAfter=20,
        alignment=1,
    )
    elements.append(Paragraph("Reporte de Entradas de Almacén", title_style))
    elements.append(Spacer(1, 0.2 * inch))

    # Fecha de generación
    elements.append(
        Paragraph(
            f"<b>Fecha de Generación:</b> {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}",
            styles["Normal"],
        )
    )
    elements.append(Spacer(1, 0.3 * inch))

    if entradas_data:
        # Encabezados de la tabla
        table_data = [
            ["Fecha/Hora", "C.C", "Material", "Cantidad", "Precio Unit.", "Total"]
        ]
        total_general = 0

        for entrada in entradas_data:
            fecha_hora, cc, material, cantidad, precio_unitario, _ = entrada
            total = cantidad * (precio_unitario or 0)
            total_general += total
            table_data.append([
                str(fecha_hora)[:19],
                str(cc),
                material[:30],
                str(cantidad),
                f"${precio_unitario:.2f}" if precio_unitario else "$0.00",
                f"${total:.2f}",
            ])

        table = Table(
            table_data,
            colWidths=[1.2 * inch, 0.6 * inch, 1.5 * inch, 0.8 * inch, 1 * inch, 1 * inch],
        )
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f77b4")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 11),
            ("BOTTOMPADDING", (0, 0), (-1, 0), 10),
            ("BACKGROUND", (0, 1), (-1, -1), colors.beige),
            ("GRID", (0, 0), (-1, -1), 1, colors.black),
            ("FONTSIZE", (0, 1), (-1, -1), 9),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f0f0f0")]),
        ]))
        elements.append(table)
        elements.append(Spacer(1, 0.3 * inch))

        # Total general
        total_style = ParagraphStyle(
            "TotalStyle",
            parent=styles["Normal"],
            fontSize=12,
            textColor=colors.HexColor("#1f77b4"),
            alignment=2,
        )
        elements.append(
            Paragraph(f"<b>TOTAL GENERAL:</b> ${total_general:,.2f}", total_style)
        )
    else:
        elements.append(
            Paragraph("No hay datos de entradas para mostrar.", styles["Normal"])
        )

    doc.build(elements)
    buffer.seek(0)
    return buffer


def create_salidas_pdf(salidas_data):
    """
    Genera un PDF con los datos de salidas.

    Args:
        salidas_data (list[tuple]): Datos de salidas obtenidos con get_salidas_data().

    Returns:
        BytesIO: Buffer con el contenido del PDF generado.
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
        "CustomTitle",
        parent=styles["Heading1"],
        fontSize=22,
        textColor=colors.HexColor("#d62728"),
        spaceAfter=20,
        alignment=1,
    )
    elements.append(Paragraph("Reporte de Salidas de Almacén", title_style))
    elements.append(Spacer(1, 0.2 * inch))

    # Fecha de generación
    elements.append(
        Paragraph(
            f"<b>Fecha de Generación:</b> {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}",
            styles["Normal"],
        )
    )
    elements.append(Spacer(1, 0.3 * inch))

    if salidas_data:
        table_data = [["Fecha/Hora", "C.C", "Material", "Cantidad/Punta", "Detalle"]]

        for salida in salidas_data:
            fecha_hora, cc, material, cantidad, nombre_punta, longitud, _ = salida
            if nombre_punta:
                detail = (
                    f"{nombre_punta} ({longitud}m)" if longitud else nombre_punta
                )
            else:
                detail = f"{cantidad} unidades"

            table_data.append([
                str(fecha_hora)[:19],
                str(cc),
                material[:30],
                str(cantidad) if not nombre_punta else "Punta",
                detail,
            ])

        table = Table(
            table_data,
            colWidths=[1.2 * inch, 0.6 * inch, 1.5 * inch, 1.2 * inch, 1.5 * inch],
        )
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#d62728")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 11),
            ("BOTTOMPADDING", (0, 0), (-1, 0), 10),
            ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#ffe6e6")),
            ("GRID", (0, 0), (-1, -1), 1, colors.black),
            ("FONTSIZE", (0, 1), (-1, -1), 9),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#fff0f0")]),
        ]))
        elements.append(table)
        elements.append(Spacer(1, 0.3 * inch))

        # Resumen
        summary_style = ParagraphStyle(
            "SummaryStyle",
            parent=styles["Normal"],
            fontSize=12,
            textColor=colors.HexColor("#d62728"),
            alignment=2,
        )
        elements.append(
            Paragraph(
                f"<b>TOTAL DE REGISTROS:</b> {len(salidas_data)}", summary_style
            )
        )
    else:
        elements.append(
            Paragraph("No hay datos de salidas para mostrar.", styles["Normal"])
        )

    doc.build(elements)
    buffer.seek(0)
    return buffer
