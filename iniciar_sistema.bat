@echo off
:: Navega a la carpeta del proyecto (ajusta la ruta a la tuya)
cd /d "C:\Users\regin\Documents\proyectos usse\almacen_usse"

:: Activa el entorno virtual
call .venv\Scripts\activate

:: Lanza Streamlit en el puerto por defecto
:: El parámetro --headline=false oculta mensajes innecesarios
streamlit run src/main_almacen.py --browser.gatherUsageStats=false

pause