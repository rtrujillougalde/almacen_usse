"""
p_salidas.py - Página de Salidas de Inventario (UI con Streamlit)

Contiene la interfaz de usuario para registrar salidas de inventario.
Toda la lógica de acceso a datos se delega al módulo data.py.
"""

import streamlit as st
import pandas as pd

from data import (
    get_all_articulo_names,
    get_article_by_name,
    get_article_by_id,
    get_available_puntas,
    get_punta_by_id,
    get_proyectos_info,
    add_salida_to_db,
    get_recent_movements,
)


# =============================================================================
# HELPERS DE SESSION STATE
# =============================================================================

def initialize_salida_session_state(form_defaults):
    """
    Inicializa las variables de session_state para el formulario de salidas.

    Args:
        form_defaults (dict): Valores por defecto para cada campo.
    """
    if "salida_showing_form" not in st.session_state:
        st.session_state.salida_showing_form = False

    for key, value in form_defaults.items():
        if f"salida_form_{key}" not in st.session_state:
            st.session_state[f"salida_form_{key}"] = value


# =============================================================================
# COMPONENTES DE FORMULARIO
# =============================================================================

def display_salida_quantity_form(articulo):
    """
    Muestra el campo de cantidad para ítems que no son cable,
    con validación de máximo disponible en stock.

    Args:
        articulo: Objeto Articulos con la información del ítem.
    """
    max_cantidad = float(articulo.cantidad_en_stock)
    st.session_state.salida_form_cantidad = st.number_input(
        f"Cantidad a retirar (Máximo disponible: {max_cantidad})",
        min_value=0.0,
        max_value=max_cantidad if max_cantidad > 0 else 0.0,
        value=(
            min(float(st.session_state.salida_form_cantidad), max_cantidad)
            if max_cantidad > 0
            else 0.0
        ),
        key="salida_form_cantidad_input",
    )


def display_salida_cable_form(articulo):
    """
    Muestra la selección de punta/carrete/tramo para ítems tipo cable.
    Solo muestra las puntas que no han sido usadas en salidas previas.

    Args:
        articulo: Objeto Articulos tipo cable.

    Returns:
        bool: True si se seleccionó una punta, False en caso contrario.
    """
    # Obtener puntas disponibles desde data.py
    available_puntas = get_available_puntas(articulo.id_articulo)

    if not available_puntas:
        st.warning("No hay puntas disponibles (todas han sido utilizadas)")
        return False

    with st.expander("📋 Seleccionar punta/carrete/tramo", expanded=True):
        punta_options = {
            f"{p['nombre_punta']} ({p['longitud']}m)": p["id_punta"]
            for p in available_puntas
        }
        punta_selected = st.selectbox(
            "Selecciona la punta a retirar:",
            options=list(punta_options.keys()),
            key="salida_form_punta_select",
        )

        if punta_selected:
            st.session_state.salida_form_id_punta = punta_options[punta_selected]
            st.session_state.salida_form_punta_nombre = punta_selected
            return True

    return False


# =============================================================================
# VALIDACIÓN Y RECOPILACIÓN DE DATOS
# =============================================================================

def validate_salida_inputs(nombre_item, articulo):
    """
    Valida las entradas del formulario de salida.

    Args:
        nombre_item (str): Nombre del ítem seleccionado.
        articulo: Objeto Articulos.

    Returns:
        list[str]: Lista de mensajes de error (vacía si no hay errores).
    """
    errors = []

    if not nombre_item:
        errors.append("Debe seleccionar un item")

    if articulo.es_cable == False:
        if st.session_state.salida_form_cantidad <= 0:
            errors.append("La cantidad debe ser mayor a 0")
        if st.session_state.salida_form_cantidad > articulo.cantidad_en_stock:
            errors.append(
                f"No hay suficiente stock (disponible: {articulo.cantidad_en_stock})"
            )
    else:
        if (
            "salida_form_id_punta" not in st.session_state
            or not st.session_state.salida_form_id_punta
        ):
            errors.append("Debe seleccionar una punta/carrete/tramo")

    return errors


def gather_salida_form_data(nombre_item, articulo):
    """
    Recopila los datos del formulario de salida en un diccionario.

    Args:
        nombre_item (str): Nombre del ítem seleccionado.
        articulo: Objeto Articulos.

    Returns:
        dict: Diccionario con los datos del formulario de salida.
    """
    return {
        "nombre_item": nombre_item,
        "id_articulo": articulo.id_articulo,
        "es_cable": articulo.es_cable,
        "cantidad": (
            st.session_state.salida_form_cantidad
            if articulo.es_cable == False
            else 0
        ),
        "id_punta": (
            st.session_state.salida_form_id_punta
            if articulo.es_cable
            else None
        ),
    }


# =============================================================================
# FORMULARIO PRINCIPAL DE SALIDA
# =============================================================================

def form_salida(nombres_articulos, proyectos_info):
    """
    Orquestador principal del formulario de salidas de inventario.
    Permite al usuario retirar múltiples ítems del inventario
    y asociarlos a un proyecto.

    Args:
        nombres_articulos (list[str]): Lista de nombres de artículos existentes.
        proyectos_info (dict): {id_proyecto: (nombre_obra, c_c)}.

    Returns:
        dict | None: Diccionario con 'movement_items' e 'id_proyecto', o None.
    """
    form_defaults = {
        "nombre_item": "",
        "cantidad": 0,
        "id_punta": None,
        "id_proyecto": None,
    }

    # Inicializar estado del movimiento
    if "salida_movement_items" not in st.session_state:
        st.session_state.salida_movement_items = []
    if "salida_current_form" not in st.session_state:
        st.session_state.salida_current_form = "closed"
    if "salida_submitted" not in st.session_state:
        st.session_state.salida_submitted = False

    initialize_salida_session_state(form_defaults)

    # ========== BOTÓN DE INICIO ==========
    if st.button("📦 Iniciar nueva salida"):
        st.session_state.salida_current_form = "open"
        st.session_state.salida_movement_items = []
        st.session_state.salida_form_id_proyecto = None
        st.session_state.salida_submitted = False

    # ========== FORMULARIO ABIERTO ==========
    if st.session_state.salida_current_form == "open":
        st.subheader("📋 Nueva Salida de Inventario")

        # --- Selección de proyecto ---
        st.subheader("Información del Proyecto")
        proyecto_options = {
            f"{v[1]} | {v[0]}": k for k, v in proyectos_info.items()
        }
        proyecto_selected = st.selectbox(
            "Selecciona un proyecto:",
            options=list(proyecto_options.keys()),
            key="salida_form_proyecto_select",
        )

        if proyecto_selected:
            id_proyecto = proyecto_options[proyecto_selected]
            st.session_state.salida_form_id_proyecto = id_proyecto
            nombre_obra, c_c = proyectos_info[id_proyecto]
            col1, col2 = st.columns(2)
            with col1:
                st.metric("Centro de Costo", c_c)
            with col2:
                st.metric("Nombre Obra", nombre_obra)

        # --- Responsable ---
        st.session_state.salida_form_responsable = st.text_input(
            "Responsable de la salida",
            value=st.session_state.get("salida_form_responsable", ""),
            key="salida_form_responsable_input",
        )

        st.divider()

        # --- Ítems ya agregados ---
        if st.session_state.salida_movement_items:
            st.write("**Items a retirar:**")
            for idx, item in enumerate(st.session_state.salida_movement_items):
                articulo = get_article_by_id(item["id_articulo"])

                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    if articulo and articulo.es_cable:
                        punta = get_punta_by_id(item["id_punta"])
                        punta_name = (
                            f" - {punta.nombre_punta}"
                            if punta
                            else " (punta no encontrada)"
                        )
                        st.write(f"{idx + 1}. {item['nombre_item']}{punta_name}")
                    else:
                        st.write(
                            f"{idx + 1}. {item['nombre_item']} - "
                            f"Cantidad: {item['cantidad']}"
                        )
                with col3:
                    if st.button("🗑️", key=f"salida_delete_{idx}"):
                        st.session_state.salida_movement_items.pop(idx)
                        st.rerun()
            st.divider()

        # --- Formulario para seleccionar ítem ---
        st.subheader("Agregar item a la salida")

        nombre_item = st.selectbox(
            "Selecciona un item existente:",
            nombres_articulos,
            key="salida_form_item_select",
        )

        if nombre_item:
            articulo = get_article_by_name(nombre_item)
            if articulo:
                if articulo.es_cable:
                    display_salida_cable_form(articulo)
                else:
                    display_salida_quantity_form(articulo)

        # --- Validación ---
        if nombre_item:
            articulo = get_article_by_name(nombre_item)
            errors = validate_salida_inputs(nombre_item, articulo)
        else:
            errors = ["Debe seleccionar un item"]

        if errors:
            st.error("\n".join(["❌ " + error for error in errors]))
            add_item_disabled = True
        else:
            add_item_disabled = False

        # --- Botones de acción ---
        col1, col2, col3 = st.columns(3)
        with col1:
            if st.button("➕ Agregar item", disabled=add_item_disabled):
                articulo = get_article_by_name(nombre_item)
                item_data = gather_salida_form_data(nombre_item, articulo)
                st.session_state.salida_movement_items.append(item_data)
                for key in form_defaults.keys():
                    st.session_state[f"salida_form_{key}"] = form_defaults[key]
                st.session_state.salida_form_id_punta = None
                st.rerun()

        with col2:
            if st.button("✅ Finalizar salida"):
                if st.session_state.salida_movement_items:
                    st.session_state.salida_current_form = "closed"
                    st.rerun()
                else:
                    st.warning("Debe agregar al menos un item")

        with col3:
            if st.button("❌ Cancelar"):
                st.session_state.salida_current_form = "closed"
                st.session_state.salida_movement_items = []

    # Retornar datos del movimiento cuando estén listos
    if (
        st.session_state.salida_current_form == "closed"
        and st.session_state.salida_movement_items
        and not st.session_state.salida_submitted
    ):
        st.session_state.salida_submitted = True
        return {
            "movement_items": st.session_state.salida_movement_items,
            "id_proyecto": st.session_state.salida_form_id_proyecto,
            "responsable": st.session_state.get("salida_form_responsable", ""),
        }

    return None


# =============================================================================
# VISUALIZACIÓN DE MOVIMIENTOS RECIENTES
# =============================================================================

def display_recent_salida_movements(proyectos_info):
    """
    Obtiene y muestra los 5 movimientos de salida más recientes.

    Args:
        proyectos_info (dict): {id_proyecto: (nombre_obra, c_c)}.
    """
    try:
        movements = get_recent_movements("salida", limit=5)

        if movements:
            for mov in movements:
                proyecto = proyectos_info.get(
                    mov["id_proyecto"], ("Sin proyecto", "N/A")
                )
                row1, row2, row3, row4 = st.columns(4)
                with row1:
                    st.write(f"Mov No. {mov['id_movimiento']}")
                with row2:
                    st.write(f"Fecha: {mov['fecha_hora'].strftime('%d/%m/%Y %H:%M') if mov['fecha_hora'] else 'N/A'}")
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
            st.write("No hay movimientos de salida registrados.")

    except Exception as e:
        st.error(f"Error al obtener movimientos de salida: {e}")


# =============================================================================
# MANEJO DE RESULTADO DEL FORMULARIO
# =============================================================================

def handle_salida_form_result(result):
    """
    Procesa el resultado del formulario de salida.
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
        add_salida_to_db(movement_items, id_proyecto, responsable=responsable)
        st.success(f"✅ Salida registrada con {len(movement_items)} item(s)")
        st.balloons()
        # Limpiar estado del formulario
        st.session_state.salida_movement_items = []
        st.session_state.salida_current_form = "closed"
        st.session_state.salida_submitted = False
    except Exception as e:
        st.error(f"❌ Error al registrar salida: {e}")
        st.session_state.salida_submitted = False


# =============================================================================
# FUNCIÓN PRINCIPAL DE LA PÁGINA
# =============================================================================

def main():
    """
    Función principal de la página de Salidas.
    Orquesta la interfaz: obtiene datos, muestra movimientos recientes
    y gestiona el formulario de nuevas salidas.
    """
    st.header("Salidas")

    # Obtener datos iniciales desde data.py
    nombres_articulos = get_all_articulo_names()
    proyectos_info = get_proyectos_info()

    # Mostrar movimientos recientes
    with st.expander("📋 Movimientos de Salida Recientes", expanded=True):
        display_recent_salida_movements(proyectos_info)

    # Formulario de nueva salida y manejo del resultado
    result = form_salida(nombres_articulos, proyectos_info)
    handle_salida_form_result(result)