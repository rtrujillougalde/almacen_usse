# Almacén USSE

Aplicación web para la gestión del almacén de herramientas y materiales de USSE. Permite consultar el inventario, registrar entradas y salidas de artículos, administrar proyectos y generar reportes en PDF y Excel.

Está construida con **Streamlit** para la interfaz, **SQLAlchemy** para el acceso a MySQL y **ReportLab** para la generación de reportes PDF.

---

## Características principales

- Visualización y edición controlada del inventario.
- Registro de entradas de materiales y herramientas.
- Registro de salidas asociadas a proyectos.
- Soporte para artículos tipo cable con puntas o tramos individuales.
- Reportes de entradas, salidas y comparativos en PDF y Excel.
- Caché de consultas frecuentes para reducir llamadas repetidas a la base de datos.

---

## Requisitos previos

- **Python 3.9+**
- **MySQL** con una base de datos creada para la aplicación
- **Git** opcional, solo si vas a clonar el repositorio

---

## Instalación

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

Dependencias principales:

| Paquete | Uso |
| --- | --- |
| `streamlit` | Interfaz web |
| `sqlalchemy` | ORM para MySQL |
| `mysql-connector-python` | Driver de conexión |
| `pandas` | Manipulación de datos |
| `numpy` | Soporte numérico |
| `reportlab` | Generación de PDFs |
| `openpyxl` | Exportación a Excel |

### 4. Configurar credenciales

La aplicación lee las credenciales desde `.streamlit/secrets.toml`.

Si no existe la carpeta `.streamlit`, créala en la raíz del proyecto. Después agrega este archivo:

```toml
[mysql_local]
user = "tu_usuario"
password = "tu_contraseña"
host = "localhost"
database = "nombre_de_tu_base_de_datos"
```

> **Importante:** no subas este archivo al repositorio.

### 5. Ejecutar la aplicación

```bash
streamlit run src/main_almacen.py
```

Se abrirá automáticamente en tu navegador. Si no, copia la dirección que aparece en la terminal (por defecto `http://localhost:8501`).

---

## Arquitectura del proyecto

El proyecto sigue una separación clara por capas:

```
┌─────────────────────────────────────────────┐
│              Interfaz de Usuario            │
│   p_entradas, p_salidas, p_inventario,      │
│   p_proyectos, p_reportes                   │
├─────────────────────────────────────────────┤
│          Capa de Acceso a Datos             │
│               (data.py)                     │
│   Consultas SQLAlchemy, lógica de datos,    │
│          generación de PDFs                 │
├─────────────────────────────────────────────┤
│         Conexión y Configuración            │
│                  utils.py                   │
│       engine, sesiones y constantes         │
├─────────────────────────────────────────────┤
│           Modelos de Datos                  │
│             (classes.py)                    │
│      Definiciones ORM (SQLAlchemy)          │
└─────────────────────────────────────────────┘
```

Las páginas de UI no construyen consultas SQL directamente. La lógica de acceso a datos está centralizada en `data.py`.

---

## Estructura del proyecto

### `src/main_almacen.py`
Punto de entrada de la aplicación. Configura Streamlit, maneja autenticación básica y navegación lateral.

### `src/classes.py`
Define los modelos ORM de SQLAlchemy:
- `Articulos`
- `Movimientos`
- `DetalleMovimiento`
- `Proyectos`
- `StockPuntas`

También contiene enums para categorías, tipos de artículo y tipos de movimiento.

### `src/data.py`
Capa central de acceso a datos. Contiene:
- Consultas de artículos, proyectos y movimientos
- Escrituras transaccionales de entradas y salidas
- Caché de consultas frecuentes con `st.cache_data`
- Generación de reportes PDF y Excel

### `src/utils.py`
Configura la conexión a MySQL y define constantes compartidas, como categorías y unidades de medida.

### `src/p_entradas.py`
Interfaz para registrar entradas de inventario, incluyendo artículos nuevos y artículos tipo cable.

### `src/p_salidas.py`
Interfaz para registrar salidas, asociarlas a proyectos y seleccionar puntas disponibles en artículos tipo cable.

### `src/p_inventario.py`
Interfaz de visualización del inventario y edición de campos permitidos. También muestra puntas disponibles para cables.

### `src/p_proyectos.py`
Interfaz para crear nuevos proyectos, capturando centro de costo, nombre de obra y encargado.

### `p_reportes.py` — Página de Reportes
Interfaz para generar y descargar reportes en PDF de entradas y salidas, con filtros por fecha y centro de costo.

---

## Notas de implementación

- Las operaciones de entrada y salida usan una sola transacción por movimiento para evitar estados parciales.
- Las consultas de lectura más frecuentes usan caché para mejorar rendimiento.
- El stock de cables se maneja mediante puntas o tramos individuales en `StockPuntas`.
- Los reportes comparativos calculan diferencias entre entradas y salidas por centro de costo.

---

## Contribución

1. Crea una rama descriptiva a partir de `main`.
2. Mantén la separación de responsabilidades actual:
   - Datos y lógica transaccional en `src/data.py`
   - UI en `src/p_*.py`
   - Modelos en `src/classes.py`
3. Verifica que la aplicación ejecute sin errores.
4. Abre un pull request con un resumen claro de los cambios.

