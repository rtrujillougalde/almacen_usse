import streamlit as st
import pandas as pd
import numpy as np

# Demo inventory data
def get_inventory():
    return pd.DataFrame({
        'ID': [1, 2, 3],
        'Product': ['Widget', 'Gadget', 'Thingamajig'],
        'Stock': [100, 50, 200],
        'Price': [10.99, 15.49, 7.99]
    })

# --- Sidebar navigation ---
st.sidebar.title('Menú de Navegación')
page = st.sidebar.radio('Ir a:', ['Inicio', 'Inventario', 'Agregar Producto', 'Ajustes', 'Demo de Widgets'])

# --- Home Page ---
if page == 'Inicio':
    st.title('Bienvenido al Sistema de Inventario USSE')
    st.image('https://cdn-icons-png.flaticon.com/512/2921/2921822.png', width=120)
    st.write('Utiliza el menú lateral para navegar entre las páginas.')
    st.success('¡Explora las funcionalidades de Streamlit!')

# --- Inventory Page ---
elif page == 'Inventario':
    st.title('Inventario Actual')
    df = get_inventory()
    st.dataframe(df)
    st.bar_chart(df.set_index('Product')['Stock'])
    st.write('Filtrar por stock mínimo:')
    min_stock = st.slider('Stock mínimo', 0, 200, 0)
    st.dataframe(df[df['Stock'] >= min_stock])

# --- Add Product Page ---
elif page == 'Agregar Producto':
    st.title('Agregar Nuevo Producto')
    with st.form('add_product_form'):
        name = st.text_input('Nombre del producto')
        stock = st.number_input('Cantidad en stock', min_value=0, value=0)
        price = st.number_input('Precio', min_value=0.0, value=0.0, step=0.01)
        submitted = st.form_submit_button('Agregar')
        if submitted:
            st.success(f'Producto "{name}" agregado con {stock} unidades a ${price:.2f}')

# --- Settings Page ---
elif page == 'Ajustes':
    st.title('Ajustes de la Aplicación')
    theme = st.selectbox('Tema', ['Claro', 'Oscuro'])
    st.write(f'Tema seleccionado: {theme}')
    st.checkbox('Activar notificaciones')
    st.radio('Idioma', ['Español', 'Inglés'])
    st.info('Estos son solo ejemplos de controles de configuración.')

# --- Demo Widgets Page ---
elif page == 'Demo de Widgets':
    st.title('Demostración de Widgets de Streamlit')
    st.header('Botones')
    if st.button('Botón simple'):
        st.write('¡Botón presionado!')
    st.header('Checkbox')
    if st.checkbox('Mostrar mensaje'):
        st.write('¡Checkbox activado!')
    st.header('Selectbox')
    color = st.selectbox('Elige un color', ['Rojo', 'Verde', 'Azul'])
    st.write(f'Color seleccionado: {color}')
    st.header('Slider')
    value = st.slider('Selecciona un valor', 0, 100, 50)
    st.write(f'Valor: {value}')
    st.header('File Uploader')
    uploaded = st.file_uploader('Sube un archivo CSV', type='csv')
    if uploaded:
        df_up = pd.read_csv(uploaded)
        st.dataframe(df_up)
    st.header('Expander')
    with st.expander('Más información'):
        st.write('Streamlit tiene muchos widgets útiles para construir apps interactivas.')
    st.header('Código y Markdown')
    st.markdown('**Ejemplo de texto en negrita**')
    st.code('print("Hola Streamlit!")', language='python')
    st.header('Gráficos')
    st.line_chart(np.random.randn(20, 3))
    st.map()  # Muestra un mapa vacío
