import streamlit as st

from utils import get_session
from classes import Articulos, StockPuntas

def main():
    st.header("Inventario")
    try:
        session = get_session()
        articulos = session.query(Articulos).all()
        # Convert to list of dicts
        data = [
            {
                #"id": a.id_articulo,
                "nombre": a.nombre,
                "cantidad en stock": a.cantidad_en_stock,
                "unidad de medida": a.unidad_medida,
                "stock minimo": a.stock_minimo,
                "categoria": a.categoria.value if a.categoria else None
            }
            for a in articulos
        ]
        st.dataframe(data)


        
        cables = (session.query(
            
            StockPuntas.nombre_punta.label("nombre de punta"),
            Articulos.nombre.label("nombre"),
            StockPuntas.longitud.label("longitud")
            )
        .join(StockPuntas, Articulos.id_articulo ==StockPuntas.id_articulo).all()
        )

        cable_names = [row.nombre for row in articulos if row.es_cable == 1]
        st.subheader("Cables en stock")
        selected_cable = st.selectbox("Selecciona un cable", cable_names) #cable cobre

        # Filter data for the selected cable
        selected_info = [row._mapping for row in cables if row.nombre == selected_cable]
        
        
        st.dataframe(selected_info)        
    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")