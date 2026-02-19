import streamlit as st
import pandas as pd
import numpy as np

# Initialize session state for page navigation
if 'page' not in st.session_state:
    st.session_state.page = 'Inicio'

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
page = st.sidebar.radio('Ir a:', ['Inicio', 'Inventario', 'Agregar Producto', 'Ajustes', 'Demo de Widgets'], index=['Inicio', 'Inventario', 'Agregar Producto', 'Ajustes', 'Demo de Widgets'].index(st.session_state.page))
st.session_state.page = page

# --- Home Page ---
if st.session_state.page == 'Inicio':
    st.markdown('<div style="height:6px;background:linear-gradient(to right, #FF5733, #F39C12, #27AE60);margin:20px 0;"></div>', unsafe_allow_html=True)
    st.markdown('<h1 style="text-align:center;color:#1C2833;">🏢 Bienvenido al Sistema de Inventario USSE</h1>', unsafe_allow_html=True)
    col1, col2, col3 = st.columns(3)
    with col2:
        st.image('https://cdn-icons-png.flaticon.com/512/2921/2921822.png', width=120)
    st.markdown('<p style="text-align:center;color:#2980B9;font-size:18px;">📍 Utiliza el menú lateral para navegar entre las páginas.</p>', unsafe_allow_html=True)
    st.success('✅ ¡Explora las funcionalidades de Streamlit!')
    
    col1, col2, col3 = st.columns(3)
    with col1:
        if st.button('📊 Inventario\nGestiona tu stock', key='btn_inventario', use_container_width=True):
            st.session_state.page = 'Inventario'
            st.rerun()
    with col2:
        if st.button('➕ Agregar\nNuevos productos', key='btn_agregar', use_container_width=True):
            st.session_state.page = 'Agregar Producto'
            st.rerun()
    with col3:
        if st.button('⚙️ Ajustes\nConfigura la app', key='btn_ajustes', use_container_width=True):
            st.session_state.page = 'Ajustes'
            st.rerun()
    
    st.markdown('<div style="height:2px;background:linear-gradient(to right, #A569BD, #7D3C98);margin:20px 0;"></div>', unsafe_allow_html=True)

# --- Inventory Page ---
elif st.session_state.page == 'Inventario':
    st.markdown('<div style="height:4px;background-color:#FF5733;margin:20px 0;"></div>', unsafe_allow_html=True)
    st.title('Inventario Actual')
    df = get_inventory()
    st.dataframe(df)
    st.bar_chart(df.set_index('Product')['Stock'])
    st.markdown('<div style="height:2px;background-color:#A569BD;margin:20px 0;"></div>', unsafe_allow_html=True)
    st.write('Filtrar por stock mínimo:')
    min_stock = st.slider('Stock mínimo', 0, 200, 0)
    st.dataframe(df[df['Stock'] >= min_stock])
    st.markdown('<div style="height:2px;background-color:#2980B9;margin:20px 0;"></div>', unsafe_allow_html=True)

# --- Add Product Page ---
elif st.session_state.page == 'Agregar Producto':
    st.markdown('<div style="height:4px;background-color:#FF5733;margin:20px 0;"></div>', unsafe_allow_html=True)
    st.title('Agregar Nuevo Producto')
    with st.form('add_product_form'):
        name = st.text_input('Nombre del producto')
        stock = st.number_input('Cantidad en stock', min_value=0, value=0)
        price = st.number_input('Precio', min_value=0.0, value=0.0, step=0.01)
        submitted = st.form_submit_button('Agregar')
        if submitted:
            st.success(f'Producto "{name}" agregado con {stock} unidades a ${price:.2f}')
    st.markdown('<div style="height:2px;background-color:#A569BD;margin:20px 0;"></div>', unsafe_allow_html=True)

# --- Settings Page ---
elif st.session_state.page == 'Ajustes':
    st.markdown('<div style="height:4px;background-color:#FF5733;margin:20px 0;"></div>', unsafe_allow_html=True)
    st.title('Ajustes de la Aplicación')
    theme = st.selectbox('Tema', ['Claro', 'Oscuro'])
    st.write(f'Tema seleccionado: {theme}')
    st.checkbox('Activar notificaciones')
    st.radio('Idioma', ['Español', 'Inglés'])
    st.info('Estos son solo ejemplos de controles de configuración.')
    st.markdown('<div style="height:2px;background-color:#A569BD;margin:20px 0;"></div>', unsafe_allow_html=True)

# --- Demo Widgets Page ---
elif st.session_state.page == 'Demo de Widgets':
    st.markdown('<div style="height:4px;background-color:#FF5733;margin:20px 0;"></div>', unsafe_allow_html=True)
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
    st.markdown('<span style="color:#FF5733;font-size:18px;">Ejemplo de texto en negrita y color</span>', unsafe_allow_html=True)
    st.code('print("Hola Streamlit!")', language='python')
    st.header('Gráficos')
    st.line_chart(np.random.randn(20, 3))
    st.map()  # Muestra un mapa vacío
    st.markdown('<div style="height:2px;background-color:#A569BD;margin:20px 0;"></div>', unsafe_allow_html=True)
