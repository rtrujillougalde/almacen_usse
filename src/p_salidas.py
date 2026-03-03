import streamlit as st
import pandas as pd
from utils import get_session, get_cables_without_salida
from classes import Articulos, StockPuntas, Movimientos, DetalleMovimiento, Proyectos

# ========== HELPER FUNCTIONS ==========

def initialize_salida_session_state(form_defaults):
    """Initialize session state variables for salida form."""
    if 'salida_showing_form' not in st.session_state:
        st.session_state.salida_showing_form = False
    
    for key, value in form_defaults.items():
        if f'salida_form_{key}' not in st.session_state:
            st.session_state[f'salida_form_{key}'] = value

def display_salida_quantity_form(articulo):
    """Display quantity input for non-cable items with max validation."""
    max_cantidad = articulo.cantidad_en_stock
    st.session_state.salida_form_cantidad = st.number_input(
        f"Cantidad a retirar (Máximo disponible: {max_cantidad})",
        min_value=0,
        max_value=int(max_cantidad) if max_cantidad > 0 else 0,
        value=min(st.session_state.salida_form_cantidad, int(max_cantidad)) if max_cantidad > 0 else 1,
        key='salida_form_cantidad_input'
    )

def display_salida_cable_form(articulo):
    """Display cable/punta selection for cable items - only showing puntas not used in previous salidas."""
    session = get_session()
    
    # Get all puntas for this article
    all_puntas = session.query(StockPuntas).filter(StockPuntas.id_articulo == articulo.id_articulo).all()
    
    if not all_puntas:
        st.warning("No hay puntas/tramos disponibles para este cable")
        return False
    
    # Get puntas that have been used in salida movements
    used_punta_ids = session.query(DetalleMovimiento.id_punta).join(
        Movimientos, Movimientos.id_movimiento == DetalleMovimiento.id_movimiento
    ).filter(
        Movimientos.tipo == 'salida',
        DetalleMovimiento.id_punta.isnot(None)
    ).distinct().all()
    
    used_ids = {punta_id[0] for punta_id in used_punta_ids}
    
    # Filter to only available puntas
    available_puntas = [p for p in all_puntas if p.id_punta not in used_ids]
    
    if not available_puntas:
        st.warning("No hay puntas disponibles (todas han sido utilizadas)")
        return False
    
    with st.expander("📋 Seleccionar punta/carrete/tramo", expanded=True):
        punta_options = {f"{p.nombre_punta} ({p.longitud}m)": p.id_punta for p in available_puntas}
        punta_selected = st.selectbox(
            "Selecciona la punta a retirar:",
            options=list(punta_options.keys()),
            key='salida_form_punta_select'
        )
        
        if punta_selected:
            st.session_state.salida_form_id_punta = punta_options[punta_selected]
            st.session_state.salida_form_punta_nombre = punta_selected
            return True
    
    return False

def validate_salida_inputs(nombre_item, articulo):
    """Validate salida form inputs."""
    errors = []
    
    if not nombre_item:
        errors.append("Debe seleccionar un item")
    
    if articulo.es_cable == False:
        if st.session_state.salida_form_cantidad <= 0:
            errors.append("La cantidad debe ser mayor a 0")
        if st.session_state.salida_form_cantidad > articulo.cantidad_en_stock:
            errors.append(f"No hay suficiente stock (disponible: {articulo.cantidad_en_stock})")
    else:
        if 'salida_form_id_punta' not in st.session_state or not st.session_state.salida_form_id_punta:
            errors.append("Debe seleccionar una punta/carrete/tramo")
    
    return errors

def gather_salida_form_data(nombre_item, articulo):
    """Gather salida form data."""
    return {
        'nombre_item': nombre_item,
        'id_articulo': articulo.id_articulo,
        'es_cable': articulo.es_cable,
        'cantidad': st.session_state.salida_form_cantidad if articulo.es_cable == False else 0,
        'id_punta': st.session_state.salida_form_id_punta if articulo.es_cable else None
    }

def form_salida(nombres_articulos: list, proyectos_info: dict):
    """
    Main form orchestrator for managing inventory exits (salidas).
    Allows users to remove items from inventory and track them by project.
    
    Args:
        nombres_articulos: List of article names
        proyectos_info: Dictionary with project ID as key and (nombre_obra, c_c) as value
    """
    form_defaults = {
        'nombre_item': '',
        'cantidad': 0,
        'id_punta': None,
        'id_proyecto': None
    }
    
    # Initialize movement in session state
    if 'salida_movement_items' not in st.session_state:
        st.session_state.salida_movement_items = []
    if 'salida_current_form' not in st.session_state:
        st.session_state.salida_current_form = 'closed'
    if 'salida_submitted' not in st.session_state:
        st.session_state.salida_submitted = False
    
    initialize_salida_session_state(form_defaults)
    
    # ========== TRIGGER BUTTON ==========
    if st.button("📦 Iniciar nueva salida"):
        st.session_state.salida_current_form = 'open'
        st.session_state.salida_movement_items = []
        st.session_state.salida_form_id_proyecto = None
        st.session_state.salida_submitted = False
    
    # ========== MOVEMENT DISPLAY ==========
    if st.session_state.salida_current_form == 'open':
        st.subheader("📋 Nueva Salida de Inventario")
        
        # --- Select Project ---
        st.subheader("Información del Proyecto")
        proyecto_options = {f"{v[1]} | {v[0]}": k for k, v in proyectos_info.items()}
        proyecto_selected = st.selectbox(
            "Selecciona un proyecto:",
            options=list(proyecto_options.keys()),
            key='salida_form_proyecto_select'
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
        
        st.divider()
        session = get_session()
        
        # Display items already added to this movement
        if st.session_state.salida_movement_items:
            st.write("**Items a retirar:**")
            
            for idx, item in enumerate(st.session_state.salida_movement_items):
                articulo = session.query(Articulos).filter(Articulos.id_articulo == item['id_articulo']).first()
                
                col1, col2, col3 = st.columns([3, 1, 1])
                with col1:
                    if articulo.es_cable:
                        punta = session.query(StockPuntas).filter(StockPuntas.id_punta == item['id_punta']).first()
                        punta_name = f" - {punta.nombre_punta}" if punta else " (punta no encontrada)"
                        st.write(f"{idx + 1}. {item['nombre_item']}{punta_name}")
                    else:
                        st.write(f"{idx + 1}. {item['nombre_item']} - Cantidad: {item['cantidad']}")
                
                with col3:
                    if st.button("🗑️", key=f"salida_delete_{idx}"):
                        st.session_state.salida_movement_items.pop(idx)
                        st.rerun()
            st.divider()
        
        # --- Form to select item ---
        st.subheader("Agregar item a la salida")
        
        nombre_item = st.selectbox(
            "Selecciona un item existente:",
            nombres_articulos,
            key='salida_form_item_select'
        )
        
        if nombre_item:
            articulo = session.query(Articulos).filter(Articulos.nombre == nombre_item).first()
            
            if articulo:
                # Show appropriate form based on item type
                if articulo.es_cable:
                    punta_selected = display_salida_cable_form(articulo)
                else:
                    display_salida_quantity_form(articulo)
        
        # --- Validate inputs ---
        if nombre_item:
            articulo = session.query(Articulos).filter(Articulos.nombre == nombre_item).first()
            errors = validate_salida_inputs(nombre_item, articulo)
        else:
            errors = ["Debe seleccionar un item"]
        
        if errors:
            st.error("\n".join(["❌ " + error for error in errors]))
            add_item_disabled = True
        else:
            add_item_disabled = False
        
        # --- Add item to movement ---
        col1, col2, col3 = st.columns(3)
        with col1:
            if st.button("➕ Agregar item", disabled=add_item_disabled):
                articulo = session.query(Articulos).filter(Articulos.nombre == nombre_item).first()
                item_data = gather_salida_form_data(nombre_item, articulo)
                st.session_state.salida_movement_items.append(item_data)
                # Reset form for next item
                for key in form_defaults.keys():
                    st.session_state[f'salida_form_{key}'] = form_defaults[key]
                st.session_state.salida_form_id_punta = None
                st.rerun()
        
        with col2:
            if st.button("✅ Finalizar salida"):
                if st.session_state.salida_movement_items:
                    st.session_state.salida_current_form = 'closed'
                    st.rerun()
                else:
                    st.warning("Debe agregar al menos un item")
        
        with col3:
            if st.button("❌ Cancelar"):
                st.session_state.salida_current_form = 'closed'
                st.session_state.salida_movement_items = []
    
    # Return movement data when ready
    if st.session_state.salida_current_form == 'closed' and st.session_state.salida_movement_items and not st.session_state.salida_submitted:
        st.session_state.salida_submitted = True
        return {
            'movement_items': st.session_state.salida_movement_items,
            'id_proyecto': st.session_state.salida_form_id_proyecto
        }
    
    return None

def add_salida_to_db(movement_items: list, id_proyecto: int = None):
    """
    Creates a Movimiento record for salida and updates stock.
    
    Args:
        movement_items: List of item dictionaries to remove
        id_proyecto: Project ID to associate with the movement
    """
    try:
        session = get_session()
        from datetime import datetime
        
        # Create movement record
        movimiento = Movimientos(
            id_proyecto=id_proyecto,
            tipo='salida',
            fecha_hora=datetime.now().isoformat(),
            observaciones=""
        )
        session.add(movimiento)
        session.commit()
        
        # Process each item
        for item_data in movement_items:
            articulo = session.query(Articulos).filter(
                Articulos.id_articulo == item_data['id_articulo']
            ).first()
            
            if not articulo:
                st.error(f"Artículo no encontrado: {item_data['nombre_item']}")
                return False
            
            if not item_data['es_cable']:
                # Non-cable item: subtract quantity from stock
                if articulo.cantidad_en_stock < item_data['cantidad']:
                    st.error(f"Stock insuficiente para {item_data['nombre_item']}")
                    return False
                
                articulo.cantidad_en_stock -= item_data['cantidad']
                session.commit()
            else:
                # Cable item: record the salida without deleting the punta
                punta = session.query(StockPuntas).filter(
                    StockPuntas.id_punta == item_data['id_punta']
                ).first()
                
                item_data['longitud'] = punta.longitud if punta else None
                if not punta:
                    st.error(f"Punta no encontrada")
                    return False
                
                # Subtract punta length from article stock
                articulo.cantidad_en_stock -= punta.longitud
                session.commit()
            st.info(f"Salida registrada para {item_data}")
            # Create detail movement record
            detalle = DetalleMovimiento(
                id_movimiento=movimiento.id_movimiento,
                id_articulo=item_data['id_articulo'],
                cantidad=item_data['cantidad'] if not item_data['es_cable'] else item_data['longitud'],  # For cables, this will be 0 since we track by punta
                id_punta=item_data['id_punta'] if item_data['es_cable'] else None
            )
            session.add(detalle)
        
        session.commit()
        return True
    
    except Exception as e:
        st.error(f"Error al registrar salida: {e}")
        return False

def display_recent_salida_movements(proyectos_info):
    """
    Fetch and display the 5 most recent salida movements.
    
    Args:
        proyectos_info: Dictionary with project information
    """
    try:
        session = get_session()
        
        # Fetch recent salida movements sorted by date
        salidas = session.query(Movimientos).filter(
            Movimientos.tipo == 'salida'
        ).order_by(Movimientos.fecha_hora.desc()).all()
        
        if salidas:
            # Process only the 5 most recent entries
            for salida in salidas[:5]:
                detalles = session.query(DetalleMovimiento).filter(
                    DetalleMovimiento.id_movimiento == salida.id_movimiento
                ).all()
                
                # Create a table for each movement
                row1, row2, row3 = st.columns(3)
                with row1:
                    st.write(f"Mov No. {salida.id_movimiento}")
                with row2:
                    st.write(f"Fecha: {salida.fecha_hora}")
                with row3:
                    st.write(f"Proyecto: {proyectos_info.get(salida.id_proyecto, ('Sin proyecto', 'N/A'))[0]} {proyectos_info.get(salida.id_proyecto, ('Sin proyecto', 'N/A'))[1]}")
                
                movement_data = []
                
                # Format each detail item
                for detalle in detalles:
                    articulo = session.query(Articulos).filter(
                        Articulos.id_articulo == detalle.id_articulo
                    ).first()
                    
                    if articulo:
                        if articulo.es_cable:
                            punta = session.query(StockPuntas).filter(
                                StockPuntas.id_punta == detalle.id_punta
                            ).first()
                            if punta:
                                item_info = f"{articulo.nombre} - {punta.nombre_punta}"
                                cantidad = f"{punta.longitud} m"
                            else:
                                item_info = f"{articulo.nombre} (punta no encontrada)"
                                cantidad = "N/A"
                        else:
                            item_info = f"{articulo.nombre}"
                            cantidad = detalle.cantidad
                        
                        movement_data.append({
                            "Item": item_info,
                            "Cantidad": cantidad
                        })
                
                # Display table
                if movement_data:
                    df = pd.DataFrame(movement_data)
                    st.dataframe(df, width='stretch')
                else:
                    st.write("No hay items en este movimiento.")
                
                st.divider()
        else:
            st.write("No hay movimientos de salida registrados.")
    
    except Exception as e:
        st.error(f"Error al obtener movimientos de salida: {e}")

def handle_salida_form_result(result):
    """
    Handle the result from the form_salida function.
    
    Args:
        result: Dictionary with 'movement_items' and 'id_proyecto' keys, or None
    """
    if result is None:
        return
    
    movement_items = result['movement_items']
    id_proyecto = result['id_proyecto']
    
    # Register movement to database
    success = add_salida_to_db(movement_items, id_proyecto)
    
    # Display feedback
    if success:
        st.success(f"✅ Salida registrada con {len(movement_items)} item(s)")
        st.balloons()
        # Clear form state
        st.session_state.salida_movement_items = []
        st.session_state.salida_current_form = 'closed'
        st.session_state.salida_submitted = False
    else:
        st.error("❌ Error al registrar salida")
        st.session_state.salida_submitted = False

def main():
    st.header("Salidas")
    
    # Fetch initial data
    session = get_session()
    nombres_articulos = [row.nombre for row in session.query(Articulos).all()]
    
    proyectos = session.query(Proyectos).all()
    proyectos_info = {
        proyecto.id_proyecto: (proyecto.nombre_obra, proyecto.c_c)
        for proyecto in proyectos
    }
    
    # Display recent salida movements
    with st.expander("📋 Movimientos de Salida Recientes", expanded=True):
        display_recent_salida_movements(proyectos_info)
    
    # Display form and handle result
    result = form_salida(nombres_articulos, proyectos_info)
    handle_salida_form_result(result)