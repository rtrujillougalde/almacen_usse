import streamlit as st
import pandas as pd
from utils import get_engine, execute_sql_query

def main():
    st.header("Inventario")
    try:
        engine = get_engine()
        query = "SELECT * FROM articulos;"
        df_mysql = pd.read_sql(query, engine)
        st.dataframe(df_mysql)
    except Exception as e:
        st.error(f"Error al conectar o consultar MySQL: {e}")
