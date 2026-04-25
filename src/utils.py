"""
utils.py - Utilidades de configuración y conexión a base de datos

Contiene la configuración de conexión a MySQL, la creación del engine
de SQLAlchemy, y constantes compartidas (categorías, unidades de medida).
"""
from pathlib import Path
from typing import Callable
import streamlit as st
import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from classes import CatEnum, TipoEnum, UbicacionEnum, AlmacenEnum

# =============================================================================
# CONSTANTES
# =============================================================================
LOGO_PATH = Path(__file__).resolve().parent.parent / "images" / "logo_usse_2.jpg"
CATEGORIAS= [e.value for e in CatEnum]
UNIDAD_DE_MEDIDA = ['pza', 'm', 'lt', 'kg', 'tramo', 'juego']
UBICACIONES = [e.value for e in UbicacionEnum]
ALMACENES = [e.value for e in AlmacenEnum]

# =============================================================================
# CONEXIÓN A BASE DE DATOS
# =============================================================================

db_user = st.secrets["mysql_local"]["user"]
db_password = st.secrets["mysql_local"]["password"]
db_host = st.secrets["mysql_local"]["host"]
db_name = st.secrets["mysql_local"]["database"]



def get_session():
    """
    Crea y devuelve una nueva sesión de SQLAlchemy.

    Returns:
        sqlalchemy.orm.Session: Sesión activa.
    """
    engine = create_engine(
        f"mysql+mysqlconnector://{db_user}:{db_password}@{db_host}/{db_name}",
        pool_pre_ping=True
    )

    Session = sessionmaker(bind=engine)
    return Session()


def check_movement_db(
    movement_items,
    state_prefix,
    dialog_title="Confirmar movimiento",
    item_formatter: Callable | None = None,
    responsable="",
    require_responsable=True,
    responsable_warning="Debe ingresar el responsable antes de confirmar el movimiento.",
):
    """
    Gestiona una confirmación con st.dialog antes de registrar un movimiento.

    Args:
        movement_items (list[dict]): Ítems del movimiento por registrar.
        state_prefix (str): Prefijo único para claves de session_state.
        dialog_title (str): Título del diálogo de confirmación.
        item_formatter (Callable | None): Función opcional para formatear cada ítem.
        responsable (str): Nombre del responsable capturado en el formulario.
        require_responsable (bool): Si True, exige responsable para confirmar.
        responsable_warning (str): Mensaje cuando falta responsable.

    Returns:
        bool: True si el usuario confirmó (Aceptar), False en cualquier otro caso.
    """
    pending_key = f"{state_prefix}_pending_confirmation"
    confirmed_key = f"{state_prefix}_confirmed_db_check"

    if pending_key not in st.session_state:
        st.session_state[pending_key] = False
    if confirmed_key not in st.session_state:
        st.session_state[confirmed_key] = False

    if st.session_state[confirmed_key]:
        st.session_state[confirmed_key] = False
        return True

    if not st.session_state[pending_key]:
        return False

    if require_responsable and str(responsable).strip() == "":
        st.session_state[pending_key] = False
        st.session_state[confirmed_key] = False
        st.warning(responsable_warning)
        return False

    def _default_item_formatter(item, idx):
        nombre_item = item.get("nombre_item", "Item")

        if item.get("es_cable"):
            nombre_punta = item.get("nombre_punta") or item.get("punta_nombre")
            longitud = item.get("longitud")

            if nombre_punta and longitud not in (None, ""):
                return (
                    f"{idx}. {nombre_item} - {nombre_punta} - "
                    f"Longitud: {longitud} m"
                )
            if nombre_punta:
                return f"{idx}. {nombre_item} - {nombre_punta}"
            if item.get("id_punta"):
                return f"{idx}. {nombre_item} - Punta ID: {item['id_punta']}"
            return f"{idx}. {nombre_item} - Cable"

        if "cantidad" in item:
            return f"{idx}. {nombre_item} - Cantidad: {item.get('cantidad')}"

        return f"{idx}. {nombre_item}"

    formatter = item_formatter or _default_item_formatter

    @st.dialog(dialog_title)
    def _display_confirmation_dialog():
        st.write("Revisa los ítems que se registrarán:")

        if movement_items:
            for idx, item in enumerate(movement_items, start=1):
                st.write(formatter(item, idx))
        else:
            st.write("No hay ítems para registrar.")

        col1, col2 = st.columns(2)
        with col1:
            if st.button("Aceptar", key=f"{state_prefix}_confirmar_aceptar"):
                st.session_state[pending_key] = False
                st.session_state[confirmed_key] = True
                st.rerun()

        with col2:
            if st.button("Cancelar", key=f"{state_prefix}_confirmar_cancelar"):
                st.session_state[pending_key] = False
                st.session_state[confirmed_key] = False
                st.rerun()

    _display_confirmation_dialog()
    return False


def initialize_prefixed_session_state(prefix, defaults):
    """
    Inicializa claves en session_state usando un prefijo común.

    Args:
        prefix (str): Prefijo de las claves (ej. "form_", "salida_form_").
        defaults (dict): Valores por defecto para cada campo.
    """
    for key, value in defaults.items():
        state_key = f"{prefix}{key}"
        if state_key not in st.session_state:
            st.session_state[state_key] = value


def render_project_selector(
    proyectos_info,
    select_label,
    select_key,
    state_project_key,
):
    """
    Renderiza la selección de proyecto y muestra métricas básicas.

    Args:
        proyectos_info (dict): {id_proyecto: (nombre_obra, c_c)}.
        select_label (str): Etiqueta del selectbox.
        select_key (str): Key del widget selectbox.
        state_project_key (str): Clave de session_state para guardar id_proyecto.

    Returns:
        int | str | None: id del proyecto seleccionado.
    """
    st.subheader("Información del Proyecto")
    proyecto_options = {
        f"{v[1]} | {v[0]}": k for k, v in proyectos_info.items()
    }
    proyecto_selected = st.selectbox(
        select_label,
        options=list(proyecto_options.keys()),
        key=select_key,
    )

    if proyecto_selected:
        id_proyecto = proyecto_options[proyecto_selected]
        st.session_state[state_project_key] = id_proyecto
        nombre_obra, c_c = proyectos_info[id_proyecto]
        col1, col2 = st.columns(2)
        with col1:
            st.metric("Centro de Costo", c_c)
        with col2:
            st.metric("Nombre Obra", nombre_obra)

    return st.session_state.get(state_project_key)


def render_responsable_input(label, state_key, input_key):
    """
    Renderiza un text_input para responsable y persiste su valor en session_state.

    Args:
        label (str): Etiqueta visible del campo.
        state_key (str): Clave de session_state para persistir valor.
        input_key (str): Key del widget text_input.

    Returns:
        str: Valor actual del responsable.
    """
    st.session_state[state_key] = st.text_input(
        label,
        value=st.session_state.get(state_key, ""),
        key=input_key,
    )
    return st.session_state[state_key]


def display_recent_movements_table(movements, proyectos_info):
    """
    Muestra una lista de movimientos recientes en formato homogéneo.

    Args:
        movements (list[dict]): Movimientos obtenidos desde data.py.
        proyectos_info (dict): {id_proyecto: (nombre_obra, c_c)}.
    """
    if movements:
        for mov in movements:
            proyecto = proyectos_info.get(
                mov["id_proyecto"], ("Sin proyecto", "N/A")
            )
            row1, row2, row3, row4 = st.columns(4)
            with row1:
                st.write(f"Mov No. {mov['id_movimiento']}")
            with row2:
                st.write(
                    f"Fecha: {mov['fecha_hora'].strftime('%d/%m/%Y %H:%M') if mov['fecha_hora'] else 'N/A'}"
                )
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
        st.write("No hay movimientos registrados.")


def handle_movement_submission(
    result,
    db_writer,
    success_message,
    reset_state,
    error_prefix,
):
    """
    Ejecuta el guardado en DB y aplica feedback/reseteo común.

    Args:
        result (dict | None): Resultado del formulario.
        db_writer (Callable): Función que recibe (movement_items, id_proyecto, responsable).
        success_message (str): Mensaje de éxito tras guardar.
        reset_state (dict): Estado a restablecer tras guardar exitosamente.
        error_prefix (str): Prefijo del mensaje de error.
    """
    if result is None:
        return

    movement_items = result["movement_items"]
    id_proyecto = result["id_proyecto"]
    responsable = result.get("responsable", "")

    try:
        db_writer(movement_items, id_proyecto, responsable)
        st.success(success_message.format(count=len(movement_items)))
        st.balloons()
        for key, value in reset_state.items():
            st.session_state[key] = value
    except Exception as e:
        st.error(f"{error_prefix}: {e}")


