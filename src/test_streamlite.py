import streamlit as st
import pandas as pd
import numpy as np

# Título de la app
st.title('Mi primera App con Streamlit')

# Un slider para que el usuario elija un número
numero = st.slider('Selecciona un valor', 0, 100, 50)

# Mostramos el resultado interactivo
st.write(f'El cuadrado de {numero} es {numero**2}')

# Crear un gráfico aleatorio
datos = pd.DataFrame(np.random.randn(20, 3), columns=['a', 'b', 'c'])
st.line_chart(datos) 


if st.button("Haz clic aquí"):
    st.write("¡Botón presionado!")