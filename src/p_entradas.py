import streamlit as st
import pandas as pd
from time import sleep
from sqlalchemy.orm import sessionmaker
from utils import get_engine, get_session, categorias, unidad_de_medida
from classes import Articulos, StockPuntas, Movimientos, DetalleMovimiento, Proyectos

# ========== HELPER FUNCTIONS ==========

def initialize_session_state(form_defaults):
    """Initialize session state variables for form persistence."""
    if 'showing_form' not in st.session_state:
        st.session_state.showing_form = False
    
    for key, value in form_defaults.items():
        if f'form_{key}' not in st.session_state:
            st.session_state[f'form_{key}'] = value

def display_new_item_form():
    """Display form fields for creating a new item."""
    with st.expander("📝 **Detalles del nuevo item**", expanded=True):
        nombre_item = st.text_input(
            "Nombre del nuevo item",
            value=st.session_state.form_nombre_item,
            key='form_nombre_item_input'
        )
        st.session_state.form_nombre_item = nombre_item
        
        st.session_state.form_tipo = st.selectbox(
            "Tipo de item",
            ["material", "herramienta"],
            index=["material", "herramienta"].index(st.session_state.form_tipo),
            key='form_tipo_select'
        )
        
        st.session_state.form_precio_unitario = st.number_input(
            "Precio unitario",
            min_value=0.0,
            value=st.session_state.form_precio_unitario,
            step=0.1,
            key='form_precio_unitario_input'
        )
        
        st.session_state.form_unidad_medida = st.selectbox(
            "Unidad de medida",
            unidad_de_medida,
            key='form_unidad_medida_select'
        )
        
        st.session_state.form_stock_minimo = st.number_input(
            "Stock mínimo para alertas",
            min_value=0,
            value=st.session_state.form_stock_minimo,
            key='form_stock_minimo_input'
        )
        
        st.session_state.form_categoria = st.selectbox(
            "Categoría",
            sorted(categorias),
            index=sorted(categorias).index(st.session_state.form_categoria) if st.session_state.form_categoria in categorias else 0,
            key='form_categoria_select'
        )
        
        st.session_state.form_es_cable = st.checkbox(
            "¿Es un cable/tramo/carrete?",
            value=st.session_state.form_es_cable,
            key='form_es_cable_check'
        )
    
    # Show cable or quantity details based on item type
    if st.session_state.form_es_cable:
        display_cable_details_form()
    else:
        display_quantity_form("form_cantidad_input_new")

def display_cable_details_form(step=0.1):
    """Display form fields for cable items (new or existing)."""
    with st.expander("📋 Detalles del cable", expanded=True):
        st.session_state.form_nombre_punta = st.text_input(
            "Nombre de la punta/carrete/tramo (e.g., 'Punta Cobre #2')",
            value=st.session_state.form_nombre_punta,
            key='form_nombre_punta_input'
        )
        st.session_state.form_longitud = st.number_input(
            "Longitud del cable (en metros)",
            min_value=0.0,
            value=st.session_state.form_longitud,
            step=step,
            key='form_longitud_input'
        )
        st.session_state.form_es_cable = True  # Ensure this is set for cable details form

def display_quantity_form(key_suffix):
    """Display quantity input for non-cable items."""
    min_value = 0 if key_suffix == "form_cantidad_input_new" else 1
    st.session_state.form_cantidad = st.number_input(
        "Cantidad a agregar",
        min_value=min_value,
        value=st.session_state.form_cantidad,
        key=key_suffix
    )

def validate_form_inputs(nombre_item, nombres_cables):
    """Validate all form inputs and return errors list."""
    errors = []
    
    if nombre_item == "Otro (escribir nuevo)":
        if not st.session_state.form_nombre_item or st.session_state.form_nombre_item.strip() == "":
            errors.append("Debe ingresar un nombre para el nuevo item")
    
    if st.session_state.form_es_cable and st.session_state.form_longitud <= 0:
        errors.append("La longitud del cable debe ser mayor a 0")
    
    if nombre_item in nombres_cables and (not st.session_state.form_nombre_punta or st.session_state.form_nombre_punta.strip() == ""):
        errors.append("Debe ingresar el nombre de la punta/carrete/tramo")
    
    return errors

def gather_form_data(nombre_item):
    """Gather all form inputs into a single dictionary."""
    return {
        'is_new': st.session_state.form_is_new,
        'nombre_item': st.session_state.form_nombre_item if st.session_state.form_is_new else nombre_item,
        'tipo': st.session_state.form_tipo,
        'precio_unitario': st.session_state.form_precio_unitario,
        'unidad_medida': st.session_state.form_unidad_medida,
        'categoria': st.session_state.form_categoria,
        'stock_minimo': st.session_state.form_stock_minimo,
        'es_cable': st.session_state.form_es_cable,
        'nombre_punta': st.session_state.form_nombre_punta,
        'longitud': st.session_state.form_longitud,
        'cantidad': st.session_state.form_cantidad
    }

def reset_form_state(form_defaults):
    """Reset all form state to default values."""
    st.session_state.showing_form = False
    for key in form_defaults.keys():
        st.session_state[f'form_{key}'] = form_defaults[key]

def form_entrada(nombres_articulos: list, nombres_cables: list, proyectos_info: dict):
    """
    Main form orchestrator for managing inventory movements.
    Allows users to add multiple items to a single 'Entrada' movement.
    Also allows users to select a project and cost center.
    
    Args:
        nombres_articulos: List of article names
        nombres_cables: List of cable article names
        proyectos_info: Dictionary with project ID as key and (nombre_obra, c_c) as value
    """
    form_defaults = {
        'is_new': False,
        'tipo': 'material',
        'nombre_item': '',
        'precio_unitario': 0.0,
        'unidad_medida': 'pieza',
        'categoria': '',
        'stock_minimo': 0,
        'es_cable': 0,
        'nombre_punta': '',
        'longitud': 0.0,
        'cantidad': 0,
        'id_proyecto': None
    }
    
    # Initialize movement in session state
    if 'movement_items' not in st.session_state:
        st.session_state.movement_items = []
    if 'current_form' not in st.session_state:
        st.session_state.current_form = 'closed'
    # Add flag to prevent duplicate form submissions
    if 'entrada_submitted' not in st.session_state:
        st.session_state.entrada_submitted = False
    
    initialize_session_state(form_defaults)
    
    # ========== TRIGGER BUTTON ==========
    if st.button("📦 Iniciar nueva entrada"):
        st.session_state.current_form = 'open'
        st.session_state.movement_items = []
        st.session_state.form_id_proyecto = None
        st.session_state.entrada_submitted = False  # Reset submission flag
    
    # ========== MOVEMENT DISPLAY ==========
    if st.session_state.current_form == 'open':
        st.subheader("📋 Nueva Entrada de Inventario")
        
        # --- Select Project ---
        st.subheader("Información del Proyecto")
        proyecto_options = {f"{v[1]} | {v[0]}": k for k, v in proyectos_info.items()}
        proyecto_selected = st.selectbox(
            "Selecciona un proyecto:",
            options=list(proyecto_options.keys()),
            key='form_proyecto_select'
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
        
        st.divider()
        session = get_session()
        # Display items already added to this movement
        if st.session_state.movement_items:
            st.write("**Items agregados a esta entrada:**")

            for idx, item in enumerate(st.session_state.movement_items):
                articulo = session.query(Articulos).filter(Articulos.nombre == item['nombre_item']).first()

                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    if st.session_state.form_es_cable == True or (articulo and articulo.es_cable !=0)  :
                        st.write(f"{idx + 1}. {item['nombre_item']} - {item['nombre_punta']} - Longitud: {item['longitud']} m")
                    else:
                        st.write(f"{idx + 1}. {item['nombre_item']} - Cantidad: {item['cantidad']}")
                    
                with col3:
                    if st.button("🗑️", key=f"delete_{idx}"):
                        st.session_state.movement_items.pop(idx)
                        st.rerun()
            st.divider()
        
        # --- Form to add single item ---
        st.subheader("Agregar item a la entrada")
        
        nombre_item = st.selectbox(
            "Selecciona un item existente o crea uno nuevo:",
            ["Otro (escribir nuevo)"] + nombres_articulos,
            key='form_item_select'
        )
        st.session_state.form_is_new = nombre_item == "Otro (escribir nuevo)"
        
        # Show appropriate form based on selection
        if nombre_item == "Otro (escribir nuevo)":
            display_new_item_form()
        elif nombre_item in nombres_cables:
            display_cable_details_form()
        else:
            display_quantity_form("form_cantidad_input_existing")
        
        # --- Validate inputs ---
        errors = validate_form_inputs(nombre_item, nombres_cables)
        
        if errors:
            st.error("\n".join(["❌ " + error for error in errors]))
            add_item_disabled = True
        else:
            add_item_disabled = False
        
        # --- Add item to movement ---
        col1, col2, col3 = st.columns(3)
        with col1:
            if st.button("➕ Agregar item", disabled=add_item_disabled):
                item_data = gather_form_data(nombre_item)
                st.session_state.movement_items.append(item_data)
                # Reset form for next item
                for key in form_defaults.keys():
                    st.session_state[f'form_{key}'] = form_defaults[key]
                st.rerun()
        
        with col2:
            if st.button("✅ Finalizar entrada"):
                if st.session_state.movement_items:
                    st.session_state.current_form = 'closed'
                    st.rerun()
                else:
                    st.warning("Debe agregar al menos un item")
        
        with col3:
            if st.button("❌ Cancelar"):
                st.session_state.current_form = 'closed'
                st.session_state.movement_items = []
    
    # Return movement data when ready - only process once per submission
    if st.session_state.current_form == 'closed' and st.session_state.movement_items and not st.session_state.entrada_submitted:
        st.session_state.entrada_submitted = True  # Mark as processed to prevent re-submission
        return {
            'movement_items': st.session_state.movement_items,
            'id_proyecto': st.session_state.form_id_proyecto
        }
    
    return None

def add_movement_to_db(movement_items: list, id_proyecto: int = None):
    """
    Creates a Movimiento record and adds DetalleMovimiento entries for each item.
    
    Args:
        movement_items: List of item dictionaries to add
        id_proyecto: Project ID to associate with the movement
    """
    try:
        session = get_session()
        from datetime import datetime
        
        # Create movement record
        movimiento = Movimientos(
            id_proyecto=id_proyecto,
            tipo='entrada',
            fecha_hora=datetime.now().isoformat(),
            observaciones=""
        )
        session.add(movimiento)
        session.commit()
        
        # Add detail records for each item
        for item_data in movement_items:
            nueva_punta = None  # Initialize to None
            if item_data['is_new']:
                # Create new article
                articulo = Articulos(
                    nombre=item_data['nombre_item'],
                    tipo=item_data['tipo'],
                    precio_unitario=item_data['precio_unitario'],
                    unidad_medida=item_data['unidad_medida'],
                    categoria=item_data['categoria'],
                    stock_minimo=item_data['stock_minimo'],
                    es_cable=1 if item_data['es_cable'] else 0,
                    cantidad_en_stock=item_data['cantidad'] if not item_data['es_cable'] else item_data['longitud']
                )
                session.add(articulo)
                session.commit()
                articulo_id = articulo.id_articulo
                
                if item_data['es_cable']:
                    nueva_punta = StockPuntas(
                        id_articulo=articulo_id,
                        nombre_punta=item_data['nombre_punta'],
                        longitud=item_data['longitud']
                    )
                    session.add(nueva_punta)
                    session.flush()  # Push to DB to get ID
                    session.refresh(nueva_punta)  # Populate id_punta
            else:
                # Update existing article
                articulo = session.query(Articulos).filter(
                    Articulos.nombre == item_data['nombre_item']
                ).first()
                articulo_id = articulo.id_articulo
                st.info(f"{item_data}")
                if item_data['es_cable']:
                    #st.info(f"Agregando nuevo tramo/carrete/punta para {articulo.nombre}")
                    nueva_punta = StockPuntas(
                        id_articulo=articulo_id,
                        nombre_punta=item_data['nombre_punta'],
                        longitud=item_data['longitud']
                    )
                    session.add(nueva_punta)
                    session.commit()
                    articulo.cantidad_en_stock += item_data['longitud']
                    session.commit()
                    st.info(f"Nuevo tramo/carrete/punta '{nueva_punta.nombre_punta}' agregado")
                else:
                    articulo.cantidad_en_stock += item_data['cantidad']
                    session.commit()
                # Create detail movement record
            detalle = DetalleMovimiento(
                id_movimiento=movimiento.id_movimiento,
                id_articulo=articulo_id,
                cantidad=item_data['cantidad'] if not item_data['es_cable'] else item_data['longitud'],
                id_punta= nueva_punta.id_punta if nueva_punta else None
            )
            session.add(detalle)
        session.commit()
        
        return True
    
    except Exception as e:
        st.error(f"Error al registrar movimiento: {e}")
        return False

def fetch_initial_data():
    """
    Fetch articles, cables, and projects from the database.
    
    Returns:
        tuple: (nombres_articulos, nombres_cables, proyectos_info) or ([], [], {}) on error
    """
    try:
        session = get_session()
        
        # Fetch all article names
        nombres_articulos = [row.nombre for row in session.query(Articulos).all()]
        
        # Fetch cable article names
        nombres_cables = [row.nombre for row in session.query(Articulos).filter(Articulos.es_cable == 1).all()]
        
        # Build projects dictionary with ID as key and (nombre_obra, c_c) as value
        proyectos = session.query(Proyectos).all()
        proyectos_info = {
            proyecto.id_proyecto: (proyecto.nombre_obra, proyecto.c_c)
            for proyecto in proyectos
        }
        
        return nombres_articulos, nombres_cables, proyectos_info
    
    except Exception as e:
        st.error(f"Error al obtener datos iniciales: {e}")
        return [], [], {}


def format_detail_item(detalle, articulo, proyectos_info, entrada):
    """
    Format a single movement detail into a display dictionary.
    Handles both cable and non-cable items with proper null checks.
    
    Args:
        detalle: DetalleMovimiento object
        articulo: Articulos object
        proyectos_info: Dictionary with project information
        entrada: Movimientos object
    
    Returns:
        dict: Formatted item data for display
    """
    session = get_session()
    proyecto_info = proyectos_info.get(entrada.id_proyecto, ("Sin proyecto", "N/A"))
    
    # Format item name and quantity based on whether it's a cable
    if articulo.es_cable == 1:
        punta = session.query(StockPuntas).filter(StockPuntas.id_punta == detalle.id_punta).first()
        
        # Handle case where punta is not found (data integrity check)
        if punta:
            item_info = f"{articulo.nombre} - {punta.nombre_punta}"
            cantidad = f"{punta.longitud} m"
        else:
            item_info = f"{articulo.nombre} (punta no encontrada)"
            cantidad = "N/A"
    else:
        item_info = f"{articulo.nombre}"
        cantidad = detalle.cantidad
    
    return {
    
        "Item": item_info,
        "Cantidad": cantidad
    }


def display_recent_entrada_movements(proyectos_info):
    """
    Fetch and display the 5 most recent entrada movements.
    Each movement gets its own table with a title showing Movement ID and datetime.
    
    Args:
        proyectos_info: Dictionary with project information
    """
    try:
        session = get_session()
        
        # Fetch recent entrada movements sorted by date
        entradas = session.query(Movimientos).filter(
            Movimientos.tipo == 'entrada'
        ).order_by(Movimientos.fecha_hora.desc()).all()
        
        
        
        if entradas:
            # Process only the 5 most recent entries
            for entrada in entradas[:5]:
                detalles = session.query(DetalleMovimiento).filter(
                    DetalleMovimiento.id_movimiento == entrada.id_movimiento
                ).all()
                
                # Create a table for each movement with title
               
                row1, row2, row3 = st.columns(3)
                with row1:
                    st.write(f"Mov No. {entrada.id_movimiento}")
                with row2:
                    st.write(f"Fecha: {entrada.fecha_hora}")
                with row3:
                    st.write(f"Proyecto: {proyectos_info.get(entrada.id_proyecto, ('Sin proyecto', 'N/A'))[0]} {proyectos_info.get(entrada.id_proyecto, ('Sin proyecto', 'N/A'))[1]}")
                movement_data = []
                
                # Format each detail item for this specific movement
                for detalle in detalles:
                    articulo = session.query(Articulos).filter(
                        Articulos.id_articulo == detalle.id_articulo
                    ).first()
                    
                    if articulo:
                        item_data = format_detail_item(detalle, articulo, proyectos_info, entrada)
                        movement_data.append(item_data)
                
                # Display table for this movement
                if movement_data:
                    df = pd.DataFrame(movement_data)
                    st.dataframe(df, width='stretch')
                else:
                    st.write("No hay items en este movimiento.")
                
                st.divider()
        else:
            st.write("No hay movimientos de entrada registrados.")
    
    except Exception as e:
        st.error(f"Error al obtener movimientos de entrada: {e}")


def handle_form_result(result):
    """
    Handle the result from the form_entrada function.
    Registers the movement to the database and displays appropriate feedback.
    
    Args:
        result: Dictionary with 'movement_items' and 'id_proyecto' keys, or None
    """
    if result is None:
        return
    
    # Extract movement data
    movement_items = result['movement_items']
    id_proyecto = result['id_proyecto']
    
    # Register movement to database
    success = add_movement_to_db(movement_items, id_proyecto)
    
    # Display feedback to user and clear form state
    if success:
        st.success(f"✅ Movimiento registrado con {len(movement_items)} item(s)")
        st.balloons()
        # Clear form state after successful submission
        st.session_state.movement_items = []
        st.session_state.current_form = 'closed'
        st.session_state.entrada_submitted = False
    else:
        st.error("❌ Error al registrar movimiento")
        st.session_state.entrada_submitted = False  # Reset flag on error so user can retry


def main():
    """
    Main orchestrator function for the Entradas (Inventory Entries) section.
    Manages the UI layout and coordinates data fetching, display, and form submission.
    """
    st.header("Entradas")
    
    # Fetch initial data needed for the form and display
    nombres_articulos, nombres_cables, proyectos_info = fetch_initial_data()
    
    # Display recent entrada movements grouped by movimiento ID

    with st.expander("📋 Movimientos de Entrada Recientes", expanded=True):
        display_recent_entrada_movements(proyectos_info)
    
    # Display form for creating new entrada and handle result
    result = form_entrada(nombres_articulos, nombres_cables, proyectos_info)
    handle_form_result(result)