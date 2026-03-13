"""
p_entradas.py - Página de Entradas de Inventario (UI con Streamlit)

Contiene la interfaz de usuario para registrar entradas de inventario.
Toda la lógica de acceso a datos se delega al módulo data.py.
"""

import streamlit as st
import pandas as pd

from utils import categorias, unidad_de_medida
from data import (
    fetch_initial_data,
    add_movement_to_db,
    get_recent_movements,
    get_article_by_name,
)


# =============================================================================
# HELPERS DE SESSION STATE
# =============================================================================

def initialize_session_state(form_defaults):
    """
    Inicializa las variables de session_state para persistencia del formulario.

    Args:
        form_defaults (dict): Valores por defecto para cada campo del formulario.
    """
    if "showing_form" not in st.session_state:
        st.session_state.showing_form = False

    for key, value in form_defaults.items():
        if f"form_{key}" not in st.session_state:
            st.session_state[f"form_{key}"] = value


def reset_form_state(form_defaults):
    """
    Restablece todos los campos del formulario a sus valores por defecto.

    Args:
        form_defaults (dict): Valores por defecto del formulario.
    """
    st.session_state.showing_form = False
    for key in form_defaults.keys():
        st.session_state[f"form_{key}"] = form_defaults[key]


# =============================================================================
# COMPONENTES DE FORMULARIO
# =============================================================================

def display_new_item_form():
    """Muestra los campos del formulario para crear un nuevo artículo."""
    with st.expander("📝 **Detalles del nuevo item**", expanded=True):
        nombre_item = st.text_input(
            "Nombre del nuevo item",
            value=st.session_state.form_nombre_item,
            key="form_nombre_item_input",
        )
        st.session_state.form_nombre_item = nombre_item
        st.session_state.form_num_catalogo = st.text_input(
            "Número de catálogo",
            value=st.session_state.form_num_catalogo,
            key="form_num_catalogo_input",
        )

        st.session_state.form_tipo = st.selectbox(
            "Tipo de item",
            ["material", "herramienta"],
            index=["material", "herramienta"].index(st.session_state.form_tipo),
            key="form_tipo_select",
        )

        st.session_state.form_precio_unitario = st.number_input(
            "Precio unitario",
            min_value=0.0,
            value=st.session_state.form_precio_unitario,
            step=0.1,
            key="form_precio_unitario_input",
        )

        st.session_state.form_unidad_medida = st.selectbox(
            "Unidad de medida",
            unidad_de_medida,
            key="form_unidad_medida_select",
        )

        st.session_state.form_stock_minimo = st.number_input(
            "Stock mínimo para alertas",
            min_value=0,
            value=st.session_state.form_stock_minimo,
            key="form_stock_minimo_input",
        )

        st.session_state.form_categoria = st.selectbox(
            "Categoría",
            sorted(categorias),
            index=(
                sorted(categorias).index(st.session_state.form_categoria)
                if st.session_state.form_categoria in categorias
                else 0
            ),
            key="form_categoria_select",
        )

        st.session_state.form_es_cable = st.checkbox(
            "¿Es un cable/tramo/carrete?",
            value=st.session_state.form_es_cable,
            key="form_es_cable_check",
        )

    # Mostrar detalles de cable o cantidad según el tipo
    if st.session_state.form_es_cable:
        display_cable_details_form()
    else:
        display_quantity_form("form_cantidad_input_new")


def display_cable_details_form(step=0.1):
    """Muestra los campos para ítems tipo cable (nombre de punta y longitud)."""
    with st.expander("📋 Detalles del cable", expanded=True):
        st.session_state.form_nombre_punta = st.text_input(
            "Nombre de la punta/carrete/tramo (e.g., 'Punta Cobre #2')",
            value=st.session_state.form_nombre_punta,
            key="form_nombre_punta_input",
        )
        st.session_state.form_longitud = st.number_input(
            "Longitud del cable (en metros)",
            min_value=0.0,
            value=st.session_state.form_longitud,
            step=step,
            key="form_longitud_input",
        )
        st.session_state.form_es_cable = True


def display_quantity_form(key_suffix):
    """
    Muestra el campo de cantidad para ítems que no son cable.

    Args:
        key_suffix (str): Sufijo único para el widget de Streamlit.
    """
    st.session_state.form_cantidad = st.number_input(
        "Cantidad a agregar",
        min_value=0,
        value=st.session_state.form_cantidad,
        key=key_suffix,
    )


# =============================================================================
# VALIDACIÓN Y RECOPILACIÓN DE DATOS
# =============================================================================

def validate_form_inputs(nombre_item, nombres_cables):
    """
    Valida las entradas del formulario y devuelve una lista de errores.

    Args:
        nombre_item (str): Nombre del ítem seleccionado.
        nombres_cables (list[str]): Lista de nombres de artículos tipo cable.

    Returns:
        list[str]: Lista de mensajes de error (vacía si no hay errores).
    """
    errors = []

    if nombre_item == "Otro (escribir nuevo)":
        if not st.session_state.form_nombre_item or st.session_state.form_nombre_item.strip() == "":
            errors.append("Debe ingresar un nombre para el nuevo item")

    if st.session_state.form_es_cable and st.session_state.form_longitud <= 0:
        errors.append("La longitud del cable debe ser mayor a 0")

    if nombre_item in nombres_cables and (
        not st.session_state.form_nombre_punta
        or st.session_state.form_nombre_punta.strip() == ""
    ):
        errors.append("Debe ingresar el nombre de la punta/carrete/tramo")

    return errors


def gather_form_data(nombre_item):
    """
    Recopila todos los datos del formulario en un diccionario.

    Args:
        nombre_item (str): Nombre del ítem seleccionado.

    Returns:
        dict: Diccionario con todos los datos del formulario.
    """
    return {
        "is_new": st.session_state.form_is_new,
        "nombre_item": (
            st.session_state.form_nombre_item
            if st.session_state.form_is_new
            else nombre_item
        ),
        "num_catalogo": st.session_state.form_num_catalogo,
        "tipo": st.session_state.form_tipo,
        "precio_unitario": st.session_state.form_precio_unitario,
        "unidad_medida": st.session_state.form_unidad_medida,
        "categoria": st.session_state.form_categoria,
        "stock_minimo": st.session_state.form_stock_minimo,
        "es_cable": st.session_state.form_es_cable,
        "nombre_punta": st.session_state.form_nombre_punta,
        "longitud": st.session_state.form_longitud,
        "cantidad": st.session_state.form_cantidad,
    }


# =============================================================================
# FORMULARIO PRINCIPAL DE ENTRADA
# =============================================================================

def form_entrada(nombres_articulos, nombres_cables, proyectos_info):
    """
    Orquestador principal del formulario de entradas de inventario.
    Permite al usuario agregar múltiples ítems a un solo movimiento de entrada,
    seleccionar un proyecto y centro de costo.

    Args:
        nombres_articulos (list[str]): Lista de nombres de artículos existentes.
        nombres_cables (list[str]): Lista de nombres de artículos tipo cable.
        proyectos_info (dict): {id_proyecto: (nombre_obra, c_c)}.

    Returns:
        dict | None: Diccionario con 'movement_items' e 'id_proyecto', o None.
    """
    form_defaults = {
        "is_new": False,
        "tipo": "material",
        "nombre_item": "",
        "num_catalogo": "",
        "precio_unitario": 0.0,
        "unidad_medida": "pieza",
        "categoria": "",
        "stock_minimo": 0,
        "es_cable": False,
        "nombre_punta": "",
        "longitud": 0.0,
        "cantidad": 0,
        "id_proyecto": None,
    }

    # Inicializar estado del movimiento
    if "movement_items" not in st.session_state:
        st.session_state.movement_items = []
    if "current_form" not in st.session_state:
        st.session_state.current_form = "closed"
    if "entrada_submitted" not in st.session_state:
        st.session_state.entrada_submitted = False

    initialize_session_state(form_defaults)

    # ========== BOTÓN DE INICIO ==========
    if st.button("📦 Iniciar nueva entrada"):
        st.session_state.current_form = "open"
        st.session_state.movement_items = []
        st.session_state.form_id_proyecto = None
        st.session_state.entrada_submitted = False

    # ========== FORMULARIO ABIERTO ==========
    if st.session_state.current_form == "open":
        st.subheader("📋 Nueva Entrada de Inventario")

        # --- Selección de proyecto ---
        st.subheader("Información del Proyecto")
        proyecto_options = {
            f"{v[1]} | {v[0]}": k for k, v in proyectos_info.items()
        }
        proyecto_selected = st.selectbox(
            "Selecciona un proyecto:",
            options=list(proyecto_options.keys()),
            key="form_proyecto_select",
        )

        if proyecto_selected:
            id_proyecto = proyecto_options[proyecto_selected]
            st.session_state.form_id_proyecto = id_proyecto
            nombre_obra, c_c = proyectos_info[id_proyecto]
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Centro de Costo", c_c)
            with col2:
                st.metric("Nombre Obra", nombre_obra)

        # --- Responsable ---
        st.session_state.form_responsable = st.text_input(
            "Responsable de la entrada",
            value=st.session_state.get("form_responsable", ""),
            key="form_responsable_input",
        )

        st.divider()

        # --- Ítems ya agregados ---
        if st.session_state.movement_items:
            st.write("**Items agregados a esta entrada:**")
            for idx, item in enumerate(st.session_state.movement_items):
                articulo = get_article_by_name(item["nombre_item"])
                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    if item.get("es_cable") or (articulo and articulo.es_cable):
                        st.write(
                            f"{idx + 1}. {item['nombre_item']} - "
                            f"{item['nombre_punta']} - Longitud: {item['longitud']} m"
                        )
                    else:
                        st.write(
                            f"{idx + 1}. {item['nombre_item']} - "
                            f"Cantidad: {item['cantidad']}"
                        )
                with col3:
                    if st.button("🗑️", key=f"delete_{idx}"):
                        st.session_state.movement_items.pop(idx)
                        st.rerun()
            st.divider()

        # --- Formulario para agregar un ítem ---
        st.subheader("Agregar item a la entrada")

        nombre_item = st.selectbox(
            "Selecciona un item existente o crea uno nuevo:",
            ["Otro (escribir nuevo)"] + nombres_articulos,
            key="form_item_select",
        )
        st.session_state.form_is_new = nombre_item == "Otro (escribir nuevo)"

        # Mostrar formulario adecuado según selección
        if nombre_item == "Otro (escribir nuevo)":
            display_new_item_form()
        elif nombre_item in nombres_cables:
            display_cable_details_form()
        else:
            display_quantity_form("form_cantidad_input_existing")

        # --- Validación ---
        errors = validate_form_inputs(nombre_item, nombres_cables)
        if errors:
            st.error("\n".join(["❌ " + error for error in errors]))
            add_item_disabled = True
        else:
            add_item_disabled = False

        # --- Botones de acción ---
        col1, col2, col3 = st.columns(3)
        with col1:
            if st.button("➕ Agregar item", disabled=add_item_disabled):
                item_data = gather_form_data(nombre_item)
                st.session_state.movement_items.append(item_data)
                for key in form_defaults.keys():
                    st.session_state[f"form_{key}"] = form_defaults[key]
                st.rerun()

        with col2:
            if st.button("✅ Finalizar entrada"):
                if st.session_state.movement_items:
                    st.session_state.current_form = "closed"
                    st.rerun()
                else:
                    st.warning("Debe agregar al menos un item")

        with col3:
            if st.button("❌ Cancelar"):
                st.session_state.current_form = "closed"
                st.session_state.movement_items = []

    # Retornar datos del movimiento cuando estén listos
    if (
        st.session_state.current_form == "closed"
        and st.session_state.movement_items
        and not st.session_state.entrada_submitted
    ):
        st.session_state.entrada_submitted = True
        return {
            "movement_items": st.session_state.movement_items,
            "id_proyecto": st.session_state.form_id_proyecto,
            "responsable": st.session_state.get("form_responsable", ""),
        }

    return None


# =============================================================================
# VISUALIZACIÓN DE MOVIMIENTOS RECIENTES
# =============================================================================

def display_recent_entrada_movements(proyectos_info):
    """
    Obtiene y muestra los 5 movimientos de entrada más recientes.
    Cada movimiento se muestra en su propia tabla con cabecera.

    Args:
        proyectos_info (dict): {id_proyecto: (nombre_obra, c_c)}.
    """
    try:
        movements = get_recent_movements("entrada", limit=5)

        if movements:
            for mov in movements:
                proyecto = proyectos_info.get(
                    mov["id_proyecto"], ("Sin proyecto", "N/A")
                )
                row1, row2, row3, row4 = st.columns(4)
                with row1:
                    st.write(f"Mov No. {mov['id_movimiento']}")
                with row2:
                    st.write(f"Fecha: {mov['fecha_hora']}")
                with row3:
                    st.write(f"C.C: {proyecto[0]} {proyecto[1]}")
                with row4:
                    st.write(f"Responsable: {mov['responsable']}") if mov.get("responsable") else st.write("Responsable: N/A")


                if mov["items"]:
                    df = pd.DataFrame(mov["items"])
                    st.dataframe(df, width="stretch")
                else:
                    st.write("No hay items en este movimiento.")

                st.divider()
        else:
            st.write("No hay movimientos de entrada registrados.")

    except Exception as e:
        st.error(f"Error al obtener movimientos de entrada: {e}")


# =============================================================================
# MANEJO DE RESULTADO DEL FORMULARIO
# =============================================================================

def handle_form_result(result):
    """
    Procesa el resultado del formulario de entrada.
    Registra el movimiento en la base de datos y muestra retroalimentación.

    Args:
        result (dict | None): Diccionario con 'movement_items' e 'id_proyecto', o None.
    """
    if result is None:
        return

    movement_items = result["movement_items"]
    id_proyecto = result["id_proyecto"]
    responsable = result.get("responsable", "")

    try:
        add_movement_to_db(movement_items, id_proyecto, responsable=responsable)
        st.success(f"✅ Movimiento registrado con {len(movement_items)} item(s)")
        st.balloons()
        # Limpiar estado del formulario
        st.session_state.movement_items = []
        st.session_state.current_form = "closed"
        st.session_state.entrada_submitted = False
    except Exception as e:
        st.error(f"❌ Error al registrar movimiento: {e}")
        st.session_state.entrada_submitted = False


# =============================================================================
# FUNCIÓN PRINCIPAL DE LA PÁGINA
# =============================================================================

def main():
    """
    Función principal de la página de Entradas.
    Orquesta la interfaz: obtiene datos, muestra movimientos recientes
    y gestiona el formulario de nuevas entradas.
    """
    st.header("Entradas")

    # Obtener datos iniciales desde data.py
    try:
        nombres_articulos, nombres_cables, proyectos_info = fetch_initial_data()
    except Exception as e:
        st.error(f"Error al obtener datos iniciales: {e}")
        return

    # Mostrar movimientos recientes
    with st.expander("📋 Movimientos de Entrada Recientes", expanded=True):
        display_recent_entrada_movements(proyectos_info)

    # Formulario de nueva entrada y manejo del resultado
    result = form_entrada(nombres_articulos, nombres_cables, proyectos_info)
    handle_form_result(result)