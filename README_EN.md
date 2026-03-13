# USSE Warehouse

Web application for managing USSE's warehouse of tools and materials. It allows users to inspect inventory, register incoming and outgoing items, manage projects, and generate PDF and Excel reports.

It is built with **Streamlit** for the UI, **SQLAlchemy** for MySQL access, and **ReportLab** for PDF generation.

---

## Main Features

- Inventory visualization with controlled field editing.
- Registration of incoming materials and tools.
- Registration of outgoing items linked to projects.
- Support for cable-type items with individual reels, segments, or tips.
- Entry, exit, and comparison reports in PDF and Excel.
- Cached read queries to reduce repeated database calls.

---

## Prerequisites

- **Python 3.9+**
- **MySQL** with a database created for the application
- **Git** optional, only if you want to clone the repository

---

## Installation

### 1. Clone the repository

```bash
git clone <repository-url>
cd almacen_usse
```

### 2. Create and activate a virtual environment

```bash
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

Main dependencies:

| Package | Purpose |
| --- | --- |
| `streamlit` | Web interface |
| `sqlalchemy` | ORM for MySQL |
| `mysql-connector-python` | Database driver |
| `pandas` | Data manipulation |
| `numpy` | Numeric support |
| `reportlab` | PDF generation |
| `openpyxl` | Excel export |

### 4. Configure credentials

The application reads credentials from `.streamlit/secrets.toml`.

If the `.streamlit` folder does not exist, create it in the project root. Then add this file:

```toml
[mysql_local]
user = "your_user"
password = "your_password"
host = "localhost"
database = "your_database_name"
```

> **Important:** do not commit this file to the repository.

### 5. Run the application

```bash
streamlit run src/main_almacen.py
```

By default, the app opens at `http://localhost:8501`.

---

## Architecture

The project follows a layered structure:

```
┌─────────────────────────────────────────────┐
│                User Interface               │
│   p_entradas, p_salidas, p_inventario,      │
│   p_proyectos, p_reportes                   │
├─────────────────────────────────────────────┤
│              Data Access Layer              │
│                  data.py                    │
│   queries, writes, caching, and reports     │
├─────────────────────────────────────────────┤
│          Connection and Configuration       │
│                  utils.py                   │
│        engine, sessions, and constants      │
├─────────────────────────────────────────────┤
│                 Data Models                 │
│                 classes.py                  │
│         SQLAlchemy tables and enums         │
└─────────────────────────────────────────────┘
```

UI pages do not build raw SQL directly. Data-access logic is centralized in `data.py`.

---

## Project Structure

### `src/main_almacen.py`
Application entry point. Configures Streamlit, handles basic authentication, and manages sidebar navigation.

### `src/classes.py`
Defines SQLAlchemy ORM models:
- `Articulos`
- `Movimientos`
- `DetalleMovimiento`
- `Proyectos`
- `StockPuntas`

It also contains enums for categories, article types, and movement types.

### `src/data.py`
Central data-access layer. It contains:
- Article, project, and movement queries
- Transactional writes for incoming and outgoing movements
- Query caching with `st.cache_data`
- PDF and Excel report generation

### `src/utils.py`
Configures the MySQL connection and defines shared constants such as categories and units of measure.

### `src/p_entradas.py`
UI for registering inventory entries, including new items and cable-type items.

### `src/p_salidas.py`
UI for registering outputs, linking them to projects, and selecting available cable tips or segments.

### `src/p_inventario.py`
Inventory view with controlled editing of allowed fields. It also displays available tips for cable items.

### `src/p_proyectos.py`
UI for creating new projects, capturing cost center, project name, and supervisor.

### `src/p_reportes.py`
UI for generating entry, exit, and comparison reports with date and cost-center filters.

---

## Implementation Notes

- Entry and exit operations use a single transaction per movement to avoid partial writes.
- Frequently used read queries are cached to improve performance.
- Cable stock is handled through individual entries in `StockPuntas`.
- Comparison reports calculate differences between entries and exits by cost center.

---

## Contributing

1. Create a descriptive branch from `main`.
2. Keep the current separation of concerns:
	- Data and transactional logic in `src/data.py`
	- UI in `src/p_*.py`
	- Models in `src/classes.py`
3. Verify that the application runs without errors.
4. Open a pull request with a clear summary of the changes.
