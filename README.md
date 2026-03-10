# Almacén USSE

Aplicación web para la gestión del almacén de herramientas y materiales de USSE. Permite controlar el inventario, registrar entradas y salidas de artículos, administrar proyectos y generar reportes en PDF.

Construida con **Streamlit** (interfaz web), **SQLAlchemy** (acceso a base de datos MySQL) y **ReportLab** (generación de PDFs).

---

## Requisitos previos

- **Python 3.9+**
- **MySQL** — La aplicación se conecta a una base de datos MySQL. Asegúrate de tener un servidor MySQL activo y una base de datos creada para la app.
- **Git** (opcional, para clonar el repositorio)

---

## Guía de instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd almacen_usse
```

### 2. Crear y activar un entorno virtual

```bash
python -m venv venv
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

Las dependencias principales son:

| Paquete                  | Uso                                      |
| ------------------------ | ---------------------------------------- |
| `streamlit`              | Framework para la interfaz web           |
| `sqlalchemy`             | ORM para interactuar con la base de datos|
| `mysql-connector-python` | Driver de conexión a MySQL               |
| `pandas` / `numpy`       | Manipulación y análisis de datos         |
| `reportlab`              | Generación de reportes en PDF            |

### 4. Configurar las credenciales de la base de datos

Streamlit utiliza un archivo de secretos para las credenciales. Crea el archivo `.streamlit/secrets.toml` en la raíz del proyecto:

```bash
mkdir .streamlit
```

Dentro de `.streamlit/secrets.toml`, agrega lo siguiente con tus datos de MySQL:

```toml
[mysql_local]
user = "tu_usuario"
password = "tu_contraseña"
host = "localhost"
database = "nombre_de_tu_base_de_datos"
```

> **Nota:** Este archivo contiene credenciales sensibles. Nunca lo subas al repositorio. Asegúrate de que `.streamlit/` esté en tu `.gitignore`.

### 5. Ejecutar la aplicación

```bash
streamlit run src/main_almacen.py
```

Se abrirá automáticamente en tu navegador. Si no, copia la dirección que aparece en la terminal (por defecto `http://localhost:8501`).

---

## Arquitectura del proyecto

La aplicación sigue una separación clara en capas:

```
┌─────────────────────────────────────────────┐
│              Interfaz de Usuario            │
│   (p_entradas, p_salidas, p_inventario,     │
│    p_proyectos, p_reportes)                 │
│         Solo código de Streamlit            │
├─────────────────────────────────────────────┤
│          Capa de Acceso a Datos             │
│               (data.py)                     │
│   Consultas SQLAlchemy, lógica de datos,    │
│          generación de PDFs                 │
├─────────────────────────────────────────────┤
│         Conexión y Configuración            │
│              (utils.py)                     │
│   Engine, sesiones, constantes globales     │
├─────────────────────────────────────────────┤
│           Modelos de Datos                  │
│             (classes.py)                    │
│      Definiciones ORM (SQLAlchemy)          │
└─────────────────────────────────────────────┘
```

**Las páginas de UI (`p_*.py`) nunca acceden directamente a la base de datos.** Todas las consultas pasan por `data.py`, lo que facilita el mantenimiento y las pruebas.

---

## Estructura del código

Todo el código fuente se encuentra en la carpeta `src/`:

### `main_almacen.py` — Punto de entrada
Configura la página de Streamlit, maneja la autenticación del usuario y gestiona la navegación entre las secciones de la app (Inventario, Entradas, Salidas, Proyectos y Reportes) mediante un menú lateral.

### `classes.py` — Modelos ORM
Define las tablas de la base de datos como clases de SQLAlchemy: `Articulos`, `Movimientos`, `DetalleMovimiento`, `Proyectos` y `StockPuntas`. También incluye los enums para categorías, tipos de artículo y tipos de movimiento.

### `data.py` — Capa de acceso a datos
Contiene **todas** las funciones que interactúan con la base de datos. Aquí se concentran las consultas, inserciones, actualizaciones y la lógica de generación de PDFs. Ninguna función en este archivo utiliza Streamlit directamente.

Secciones principales:
- **Artículos:** Obtener, buscar y actualizar artículos del inventario.
- **Cables y Puntas:** Consultar tipos de cable, puntas disponibles y stock.
- **Proyectos:** Crear y listar proyectos con sus centros de costo.
- **Movimientos de Entrada:** Registrar entradas y consultar movimientos recientes.
- **Movimientos de Salida:** Registrar salidas, descontando del inventario.
- **Reportes:** Consultar datos y generar PDFs de entradas y salidas.

### `utils.py` — Configuración y conexión
Provee la conexión a la base de datos (`get_engine()`, `get_session()`) y constantes compartidas como las categorías de artículos y unidades de medida.

### `p_entradas.py` — Página de Entradas
Interfaz para registrar entradas de artículos al almacén. Permite seleccionar artículos, ingresar cantidades y confirmar el movimiento. Muestra un historial de las entradas recientes.

### `p_salidas.py` — Página de Salidas
Interfaz para registrar salidas de artículos del almacén. Permite asociar la salida a un proyecto, seleccionar artículos (incluyendo selección de puntas para cables) y confirmar el movimiento.

### `p_inventario.py` — Página de Inventario
Interfaz para visualizar y editar el inventario actual. Muestra todos los artículos con sus cantidades, permite editar campos, y para cables muestra el detalle de puntas disponibles.

### `p_proyectos.py` — Página de Proyectos
Interfaz para dar de alta nuevos proyectos, capturando nombre, descripción y centro de costo.

### `p_reportes.py` — Página de Reportes
Interfaz para generar y descargar reportes en PDF de entradas y salidas, con filtros por fecha y centro de costo.

### `test.py` — Archivo de pruebas
Archivo para pruebas de desarrollo y validación de funciones.

---

## Cómo contribuir

1. Crea una rama a partir de `main` con un nombre descriptivo.
2. Realiza tus cambios siguiendo la arquitectura existente:
   - Lógica de datos → `data.py`
   - Interfaz de usuario → `p_*.py`
   - Modelos nuevos → `classes.py`
3. Verifica que la aplicación corre sin errores.
4. Haz un pull request describiendo los cambios realizados.

