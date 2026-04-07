"""
data.py - Capa de acceso a datos (Data Access Layer)

Contiene todas las funciones que interactúan con la base de datos MySQL
usando SQLAlchemy. No contiene llamadas a Streamlit.
Todas las funciones de consulta y manipulación de datos están centralizadas aquí.
"""
import streamlit as st  # Solo para manejo de caché, no para UI
from datetime import datetime

from sqlalchemy import String, and_, cast, func
from sqlalchemy.orm import load_only, sessionmaker

from classes import (
    Articulos,
    DetalleMovimiento,
    Movimientos,
    Proveedores,
    Proyectos,
    StockPuntas,
)
from utils import get_session


def clear_cached_reference_data():
    """Limpia caches de lectura afectados por escrituras de inventario."""
    cached_funcs = [
        get_all_articulos,
        get_all_articulo_names,
        get_cable_names,
        get_available_puntas,
        get_proyectos_info,
        get_proyectos_table_data,
    ]
    for fn in cached_funcs:
        clear_method = getattr(fn, "clear", None)
        if callable(clear_method):
            clear_method()


# =============================================================================
# ARTÍCULOS
# =============================================================================
#@st.cache_data(ttl=300)  # Cachear por 5 minutos para mejorar rendimiento
def get_all_articulos():
    """
    Obtiene todos los artículos de la base de datos.

    Returns:
        list[dict]: Lista de diccionarios con los datos de cada artículo.
    """
    session = get_session()
    try:
        # Consultar columnas concretas evita fallos por conversión estricta de Enum
        # cuando hay valores históricos que no coinciden con la definición Python.
        rows = (
            session.query(
                Articulos.id_articulo.label("id"),
                Articulos.nombre,
                Articulos.num_catalogo,
                Articulos.cantidad_en_stock,
                Articulos.unidad_medida,
                Articulos.stock_minimo,
                cast(Articulos.tipo, String).label("tipo"),
                cast(Articulos.categoria, String).label("categoria"),
                Proveedores.nombre.label("proveedor"),
            )
            .outerjoin(Proveedores, Proveedores.id_proveedor == Articulos.proveedor)
            .all()
        )

        return [
            {
                "id": row.id,
                "nombre": row.nombre,
                "num_catalogo": row.num_catalogo,
                "cantidad en stock": round(row.cantidad_en_stock, 2)
                if row.cantidad_en_stock is not None
                else 0.00,
                "unidad de medida": row.unidad_medida,
                "stock minimo": round(row.stock_minimo, 2)
                if row.stock_minimo is not None
                else 0.00,
                "tipo": row.tipo,
                "categoria": row.categoria,
                "proveedor": row.proveedor,
            }
            for row in rows
        ]
    except Exception as e:
        print(f"Error al obtener artículos: {e}")
        return []

    finally:
        session.close()

# @st.cache_data(ttl=300)
def get_all_articulo_names():
    """
    Obtiene los nombres de todos los artículos.

    Returns:
        list[str]: Lista de nombres de artículos.
    """
    session = get_session()
    try:
        rows = session.query(Articulos.nombre).order_by(Articulos.nombre).all()
        return [row.nombre for row in rows]
    except Exception as e:
        print(f"Error al obtener nombres de artículos: {e}")
        return []
    
    finally:
        session.close()

# @st.cache_data(ttl=300)
def get_cable_names():
    """
    Obtiene los nombres de todos los artículos que son cables.

    Returns:
        list[str]: Lista de nombres de artículos tipo cable.
    """
    session = get_session()
    try:
        rows = (
            session.query(Articulos.nombre)
            .filter(Articulos.es_cable.is_(True))
            .order_by(Articulos.nombre)
            .all()
        )
        return [row.nombre for row in rows]
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
        return (
            session.query(Articulos)
            .options(
                load_only(
                    Articulos.id_articulo,
                    Articulos.nombre,
                    Articulos.num_catalogo,
                    Articulos.cantidad_en_stock,
                    Articulos.unidad_medida,
                    Articulos.es_cable,
                    Articulos.stock_minimo,
                    Articulos.precio_unitario,
                    Articulos.proveedor,
                )
            )
            .filter(Articulos.nombre == nombre)
            .first()
        )
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
        return (
            session.query(Articulos)
            .options(
                load_only(
                    Articulos.id_articulo,
                    Articulos.nombre,
                    Articulos.num_catalogo,
                    Articulos.cantidad_en_stock,
                    Articulos.unidad_medida,
                    Articulos.es_cable,
                    Articulos.stock_minimo,
                    Articulos.precio_unitario,
                    Articulos.proveedor,
                )
            )
            .filter(Articulos.id_articulo == id_articulo)
            .first()
        )
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
# @st.cache_data(ttl=300)
def get_available_puntas(id_articulo: int):
    """
    Obtiene las puntas disponibles para un artículo cable,
    excluyendo las que ya fueron utilizadas en movimientos de salida.

    Args:
        id_articulo (int): ID del artículo cable.

    Returns:
        list[dict]: Lista de diccionarios con id, nombre y longitud de cada punta.
    """
    session = get_session()
    try:
        used_puntas_subquery = session.query(DetalleMovimiento.id_punta).join(
            Movimientos, DetalleMovimiento.id_movimiento == Movimientos.id_movimiento
        ).filter(
            Movimientos.tipo == "salida",
            DetalleMovimiento.id_punta.isnot(None),
        ).distinct()

        puntas = session.query(
            StockPuntas.id_punta,
            StockPuntas.nombre_punta,
            StockPuntas.longitud,
            StockPuntas.color,
        ).filter(
            StockPuntas.id_articulo == id_articulo,
            ~StockPuntas.id_punta.in_(used_puntas_subquery),
        ).order_by(StockPuntas.id_punta).all()

        return [
            {
                "id_punta": punta.id_punta,
                "nombre_punta": punta.nombre_punta,
                "longitud": punta.longitud,
                "color": punta.color
            }
            for punta in puntas
        ]
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


# @st.cache_data(ttl=300)
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


#@st.cache_data(ttl=300)
def get_proyectos_table_data():
    """
    Obtiene los proyectos en formato tabular para la UI.

    Returns:
        list[dict]: Lista de diccionarios con id, centro de costo, obra y encargado.
    """
    session = get_session()
    try:
        proyectos = session.query(Proyectos).order_by(Proyectos.c_c, Proyectos.nombre_obra).all()
        return [
            {
                
                "C.C": p.c_c,
                "Obra": p.nombre_obra,
                "Encargado": p.encargado,
            }
            for p in proyectos
        ]
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
        clear_cached_reference_data()
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
# PROVEEDORES
# =============================================================================

#@st.cache_data(ttl=300)
def get_proveedores_table_data():
    """
    Obtiene los proveedores en formato tabular para la UI.

    Returns:
        list[dict]: Lista de diccionarios con datos de proveedores.
    """
    session = get_session()
    try:
        proveedores = session.query(Proveedores).order_by(Proveedores.nombre).all()
        return [
            {
                "Nombre": p.nombre,
                "Teléfono": p.telefono,
                "Email": p.email,
                "Página Web": p.pagina_web,
                "Dirección": p.direccion,
                "Contacto": p.contacto,
                "Notas": p.notas
            }
            for p in proveedores
        ]
    finally:
        session.close()


#@st.cache_data(ttl=300)
def get_proveedores_for_edit():
    """
    Obtiene proveedores con campos completos para selección/edición en UI.

    Returns:
        list[dict]: Lista con id y datos del proveedor.
    """
    session = get_session()
    try:
        proveedores = session.query(Proveedores).order_by(Proveedores.nombre, Proveedores.id_proveedor).all()
        return [
            {
                "id_proveedor": p.id_proveedor,
                "nombre": p.nombre,
                "telefono": p.telefono,
                "email": p.email,
                "pagina_web": p.pagina_web,
                "direccion": p.direccion,
                "contacto": p.contacto,
            }
            for p in proveedores
        ]
    finally:
        session.close()


def add_proveedor(nombre, telefono=None, email=None, pagina_web=None, direccion=None, contacto=None, notas=None):
    """
    Agrega un nuevo proveedor a la base de datos.

    Args:
        nombre (str): Nombre del proveedor (obligatorio).
        telefono (str, optional): Teléfono del proveedor.
        email (str, optional): Correo electrónico del proveedor.
        pagina_web (str, optional): Página web del proveedor.
        direccion (str, optional): Dirección del proveedor.
        contacto (str, optional): Persona de contacto del proveedor.
        notas (str, optional): Notas adicionales sobre el proveedor.

    Returns:
        Proveedores: El proveedor creado.

    Raises:
        ValueError: Si el nombre está vacío.
        Exception: Si ocurre un error en la base de datos.
    """
    nombre_limpio = (nombre or "").strip()
    if not nombre_limpio:
        raise ValueError("El nombre del proveedor es obligatorio")

    def to_none_if_empty(value):
        cleaned = (value or "").strip()
        return cleaned if cleaned else None

    session = get_session()
    try:
        nuevo_proveedor = Proveedores(
            nombre=nombre_limpio,
            telefono=to_none_if_empty(telefono),
            email=to_none_if_empty(email),
            pagina_web=to_none_if_empty(pagina_web),
            direccion=to_none_if_empty(direccion),
            contacto=to_none_if_empty(contacto),
            notas=to_none_if_empty(notas)
        )
        session.add(nuevo_proveedor)
        session.flush()  # Para obtener el ID asignado antes de commit
        session.commit()

        clear_method = getattr(get_proveedores_table_data, "clear", None)
        if callable(clear_method):
            clear_method()

        return nuevo_proveedor
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def update_proveedor(id_proveedor, nombre, telefono=None, email=None, pagina_web=None, direccion=None, contacto=None):
    """
    Actualiza un proveedor existente.

    Args:
        id_proveedor (int): ID del proveedor a actualizar.
        nombre (str): Nombre del proveedor (obligatorio).
        telefono (str, optional): Teléfono del proveedor.
        email (str, optional): Correo electrónico del proveedor.
        pagina_web (str, optional): Página web del proveedor.
        direccion (str, optional): Dirección del proveedor.
        contacto (str, optional): Persona de contacto del proveedor.

    Returns:
        Proveedores: El proveedor actualizado.

    Raises:
        ValueError: Si el proveedor no existe o nombre está vacío.
        Exception: Si ocurre un error de base de datos.
    """
    nombre_limpio = (nombre or "").strip()
    if not nombre_limpio:
        raise ValueError("El nombre del proveedor es obligatorio")

    def to_none_if_empty(value):
        cleaned = (value or "").strip()
        return cleaned if cleaned else None

    session = get_session()
    try:
        proveedor = session.query(Proveedores).filter(
            Proveedores.id_proveedor == id_proveedor
        ).first()

        if not proveedor:
            raise ValueError(f"Proveedor con ID {id_proveedor} no encontrado")

        proveedor.nombre = nombre_limpio
        proveedor.telefono = to_none_if_empty(telefono)
        proveedor.email = to_none_if_empty(email)
        proveedor.pagina_web = to_none_if_empty(pagina_web)
        proveedor.direccion = to_none_if_empty(direccion)
        proveedor.contacto = to_none_if_empty(contacto)

        session.commit()

        for fn in (get_proveedores_table_data, get_proveedores_for_edit):
            clear_method = getattr(fn, "clear", None)
            if callable(clear_method):
                clear_method()

        return proveedor
    except Exception:
        session.rollback()
        raise
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
            fecha_hora=datetime.now(),
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
                    num_catalogo=item_data.get("num_catalogo", ""),
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
                        color = item_data["color"]
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
                    session.flush()
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
        #clear_cached_reference_data()
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
            Articulos.unidad_medida,
            StockPuntas.nombre_punta,
            StockPuntas.longitud,
            StockPuntas.color,
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
                    item_info = f"{detalle.nombre} - {detalle.nombre_punta} - {detalle.color}"
                    cantidad = f"{detalle.longitud} {detalle.unidad_medida}(s)"
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
            fecha_hora=datetime.now(),
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
        #clear_cached_reference_data()
        return True
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


# =============================================================================
# REPORTES - CONSULTAS
# =============================================================================

def get_report_data(fecha_inicio=None, fecha_fin=None, cc_selected=None, movement_type="entrada"):
    """
    Obtiene datos de entradas para generación de reportes.

    Args:
        fecha_inicio (str, optional): Fecha de inicio en formato 'YYYY-MM-DD'.
        fecha_fin (str, optional): Fecha de fin en formato 'YYYY-MM-DD'.
        cc_selected (int | list[int], optional): Centro(s) de costo a filtrar.

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
            Articulos.unidad_medida
        ).join(
            DetalleMovimiento,
            Movimientos.id_movimiento == DetalleMovimiento.id_movimiento,
        ).join(
            Articulos, DetalleMovimiento.id_articulo == Articulos.id_articulo
        ).join(
            Proyectos, Movimientos.id_proyecto == Proyectos.id_proyecto
        ).filter(Movimientos.tipo == movement_type)

        # Filtros de fecha
        if fecha_inicio and fecha_fin:
            query = query.filter(
                and_(
                    func.date(Movimientos.fecha_hora) >= fecha_inicio,
                    func.date(Movimientos.fecha_hora) <= fecha_fin,
                )
            )

        # Filtro de centro de costo
        if cc_selected is not None:
            if isinstance(cc_selected, list):
                query = query.filter(Proyectos.c_c.in_(cc_selected))
            else:
                query = query.filter(Proyectos.c_c == cc_selected)

        return query.order_by(Movimientos.fecha_hora.desc()).all()
    finally:
        session.close()


# =============================================================================
# REPORTES - GENERACIÓN DE PDF
# =============================================================================

def get_comparacion_data(fecha_inicio=None, fecha_fin=None, cc_selected=None):
    """
    Obtiene datos agrupados de entradas y salidas por artículo para un centro de costo,
    permitiendo comparar cuánto entró vs cuánto salió.

    Args:
        fecha_inicio (str, optional): Fecha de inicio 'YYYY-MM-DD'.
        fecha_fin (str, optional): Fecha de fin 'YYYY-MM-DD'.
        cc_selected (int | list[int], optional): Centro(s) de costo a filtrar.

    Returns:
        list[dict]: Lista de diccionarios con campos:
            c_c, material, tipo, total_entrada, total_salida, diferencia, porcentaje_uso
    """
    session = get_session()
    try:
        date_filters = []
        if fecha_inicio and fecha_fin:
            date_filters = [
                func.date(Movimientos.fecha_hora) >= fecha_inicio,
                func.date(Movimientos.fecha_hora) <= fecha_fin,
            ]

        cc_selecteds = []
        if cc_selected is not None:
            if isinstance(cc_selected, list):
                cc_selecteds = [Proyectos.c_c.in_(cc_selected)]
            else:
                cc_selecteds = [Proyectos.c_c == cc_selected]

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
            .filter(*date_filters, *cc_selecteds)
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
            item["usado"] = item["total_salida"] - item["total_entrada"]
            costo_herramienta = item["total_salida"] * item["precio_unitario"]
            if item["tipo"] == "herramienta":
                item["costo_material_usado"] = costo_herramienta * 0.05 #depreciación del 5% por uso
            else:
                item["costo_material_usado"] = item["precio_unitario"] * item["usado"]
            result.append(item)

        result.sort(key=lambda x: (x["c_c"], x["material"]))
        return result
    finally:
        session.close()


