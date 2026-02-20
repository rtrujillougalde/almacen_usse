import streamlit as st
from time import sleep
from sqlalchemy.orm import sessionmaker
from utils import get_engine, get_session, categorias, unidad_de_medida
from classes import Articulos, StockPuntas

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

def display_cable_details_form():
    """Display form fields specific to cable items."""
    with st.expander("📋 Detalles del cable", expanded=True):
        st.session_state.form_nombre_punta = st.text_input(
            "Nombre de la punta/carrete/tramo (e.g., 'Punta Cobre #2')",
            value=st.session_state.form_nombre_punta,
            key='form_nombre_punta_input'
        )
        st.session_state.form_longitud = st.number_input(
            "Longitud (en metros)",
            min_value=0.0,
            value=st.session_state.form_longitud,
            step=0.1,
            key='form_longitud_input'
        )

def display_existing_cable_form():
    """Display form fields for adding to an existing cable."""
    with st.expander("📋 Detalles del cable", expanded=True):
        st.session_state.form_nombre_punta = st.text_input(
            "Nombre de la punta/carrete/tramo (e.g., 'Punta Cobre #2')",
            value=st.session_state.form_nombre_punta,
            key='form_nombre_punta_existing'
        )
        st.session_state.form_longitud = st.number_input(
            "Longitud del cable (en metros)",
            min_value=0.0,
            value=st.session_state.form_longitud,
            step=0.1,
            key='form_longitud_existing'
        )

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

def form_entrada(nombres_articulos, nombres_cables):
    """
    Main form orchestrator for adding inventory items.
    Delegates to specialized functions for each responsibility.
    """
    form_defaults = {
        'is_new': False,
        'tipo': 'material',
        'nombre_item': '',
        'precio_unitario': 0.0,
        'unidad_medida': 'pieza',
        'categoria': '',
        'stock_minimo': 0,
        'es_cable': False,
        'nombre_punta': '',
        'longitud': 0.0,
        'cantidad': 1
    }
    
    initialize_session_state(form_defaults)
    
    # ========== TRIGGER BUTTON ==========
    if st.button("Añadir nuevo item al inventario"):
        st.session_state.showing_form = True
    
    # ========== FORM DISPLAY ==========
    if st.session_state.showing_form:
        st.subheader("📦 Agregar Nuevo Item")
        
        # --- Step 1: Select or create item ---
        nombre_item = st.selectbox(
            "Selecciona un item existente o crea uno nuevo:",
            ["Otro (escribir nuevo)"] + nombres_articulos,
            key='form_item_select'
        )
        st.session_state.form_is_new = nombre_item == "Otro (escribir nuevo)"
        
        # --- Step 2: Show appropriate form based on selection ---
        if nombre_item == "Otro (escribir nuevo)":
            display_new_item_form()
        elif nombre_item in nombres_cables:
            display_existing_cable_form()
        else:
            display_quantity_form("form_cantidad_input_existing")
        
        # --- Step 3: Validate inputs ---
        errors = validate_form_inputs(nombre_item, nombres_cables)
        
        if errors:
            st.error("\n".join(["❌ " + error for error in errors]))
            submit_disabled = True
        else:
            submit_disabled = False
        
        # --- Step 4: Action buttons ---
        col1, col2 = st.columns(2)
        with col1:
            if st.button("✅ Agregar al inventario", disabled=submit_disabled):
                form_data = gather_form_data(nombre_item)
                reset_form_state(form_defaults)
                st.rerun()
                return form_data
        
        with col2:
            if st.button("❌ Cancelar"):
                reset_form_state(form_defaults)
    
    return None
def add_article_to_db(form_data: dict):
    """
    Inserts a new article into the database based on the provided form data.
    Handles both new articles and updates to existing cables.
    """
    try:
        session = get_session()
        
        if form_data['is_new']:
            # Create new article
            nuevo_articulo = Articulos(
                nombre=form_data['nombre_item'],
                tipo=form_data['tipo'],
                precio_unitario=form_data['precio_unitario'],
                unidad_medida=form_data['unidad_medida'],
                categoria=form_data['categoria'],
                stock_minimo=form_data['stock_minimo'],
                es_cable=1 if form_data['es_cable'] else 0,
                cantidad_en_stock=form_data['cantidad'] if not form_data['es_cable'] else 0
            )
            session.add(nuevo_articulo)
            session.commit()
            
            if form_data['es_cable']:
                # Add cable details to StockPuntas
                nueva_punta = StockPuntas(
                    articulo_id=nuevo_articulo.id,
                    nombre_punta=form_data['nombre_punta'],
                    longitud=form_data['longitud']
                )
                session.add(nueva_punta)
                session.commit()
        
        elif not form_data['is_new'] and form_data['es_cable']:
            # Update existing cable with new punta/length
            articulo = session.query(Articulos).filter(Articulos.nombre == form_data['nombre_item']).first()
            if articulo:
                nueva_punta = StockPuntas(
                    articulo_id=articulo.id,
                    nombre_punta=form_data['nombre_punta'],
                    longitud=form_data['longitud']
                )
                session.add(nueva_punta)
                session.commit()
        
        elif not form_data['is_new'] and not form_data['es_cable']:
            # Update existing non-cable item stock quantity
            articulo = session.query(Articulos).filter(Articulos.nombre == form_data['nombre_item']).first()
            if articulo:
                articulo.cantidad_en_stock += form_data['cantidad']
                session.commit()
        
        return True
    
    except Exception as e:
        st.error(f"Error al agregar artículo a la base de datos: {e}")
        return False

def main():
    st.header("Entradas")
    try:
        session = get_session()
        # Obtener nombres de artículos existentes
        nombres_articulos = [row.nombre for row in session.query(Articulos).all()]
        nombres_cables = [row.nombre for row in session.query(Articulos).filter(Articulos.es_cable == 1).all()]

    except Exception as e:
        st.error(f"Error al obtener artículos: {e}")
        nombres_articulos = []
        nombres_cables = []

        
    info_articulo = form_entrada(nombres_articulos, nombres_cables)
    if info_articulo:
        success = add_article_to_db(info_articulo)
        if success:
            st.success("Artículo agregado exitosamente a la base de datos")
            st.balloons()
        else:
            st.error("Hubo un error al agregar el artículo a la base de datos")