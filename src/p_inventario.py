import streamlit as st

from utils import get_session, get_cables_without_salida
from classes import Articulos, StockPuntas, DetalleMovimiento, Movimientos

def main():
    st.header("Inventario")
    try:
        session = get_session()
        
        # Display all articulos with editing capability
        articulos = session.query(Articulos).all()
        data = [
            {
                "id": a.id_articulo,
                "nombre": a.nombre,
                "cantidad en stock": a.cantidad_en_stock,
                "unidad de medida": a.unidad_medida,
                "stock minimo": a.stock_minimo,
                "categoria": a.categoria.value if a.categoria else None
            }
            for a in articulos
        ]
        
        st.subheader("Articulos")
        edited_data = st.data_editor(data, hide_index=True, use_container_width=True)
        
        # Save changes to database
        if edited_data != data:
            try:
                for edited_row, original_row in zip(edited_data, data):
                    if edited_row != original_row:
                        articulo = session.query(Articulos).filter(
                            Articulos.id_articulo == edited_row["id"]
                        ).first()
                        if articulo:
                            articulo.nombre = edited_row["nombre"]
                            articulo.cantidad_en_stock = edited_row["cantidad en stock"]
                            articulo.unidad_medida = edited_row["unidad de medida"]
                            articulo.stock_minimo = edited_row["stock minimo"]
                session.commit()
                st.success("Cambios guardados")
            except Exception as e:
                st.error(f"Error al guardar cambios: {e}")
                session.rollback()
        
        # Get all cable types
        cable_types = session.query(Articulos).filter(Articulos.es_cable == 1).all()
        cable_names = [cable.nombre for cable in cable_types]
        
        st.subheader("Cables en stock")
        selected_cable = st.selectbox("Selecciona un cable", cable_names)
        
        # Get puntas with salida movements (to exclude them)
        from sqlalchemy import and_
        puntas_with_salida = session.query(DetalleMovimiento.id_punta).join(
            Movimientos, DetalleMovimiento.id_movimiento == Movimientos.id_movimiento
        ).filter(Movimientos.tipo == "salida").distinct().all()
        
        salida_punta_ids = {row.id_punta for row in puntas_with_salida}
        
        # Get all puntas for the selected cable excluding those with salida movements
        cable_puntas = session.query(
            StockPuntas.nombre_punta.label("nombre de punta"),
            StockPuntas.longitud.label("longitud")
        ).join(
            Articulos, StockPuntas.id_articulo == Articulos.id_articulo
        ).filter(
            Articulos.nombre == selected_cable,
            ~StockPuntas.id_punta.in_(salida_punta_ids)
        ).all()
        
        st.dataframe([row._mapping for row in cable_puntas])
        session.close()
        
    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")