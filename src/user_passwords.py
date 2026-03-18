"""
user_passwords.py - Gestión de autenticación de la aplicación

Define usuarios, roles y permisos por página. Maneja login con
bloqueo temporal tras intentos fallidos y cierre de sesión.

Configuración en .streamlit/secrets.toml:

    [app_auth.users.admin]
    password_hash = "<sha256_hex>"
    role = "admin"

    [app_auth.users.almacenista]
    password_hash = "<sha256_hex>"
    role = "operador"

    [app_auth.roles]
    admin    = ["Inventario", "Entradas", "Salidas", "Proyectos", "Reportes"]
    operador = ["Inventario", "Entradas", "Salidas"]
    consulta = ["Inventario", "Reportes"]
"""

import hashlib
import hmac
from datetime import datetime, timedelta

import streamlit as st
from utils import LOGO_PATH

# =============================================================================
# CONFIGURACIÓN
# =============================================================================
ALL_PAGES = ("Inventario", "Entradas", "Salidas", "Proyectos", "Reportes")
MAX_LOGIN_ATTEMPTS = 5
LOCKOUT_SECONDS = 60


# =============================================================================
# FUNCIONES DE AUTENTICACIÓN
# =============================================================================

def hash_password(password: str) -> str:
    """Genera el hash SHA-256 hexadecimal de una contraseña."""
    return hashlib.sha256(password.encode("utf-8")).hexdigest()


def _get_auth_config():
    """Lee la sección app_auth de secrets.toml."""
    if "app_auth" not in st.secrets or "users" not in st.secrets["app_auth"]:
        raise RuntimeError(
            "Falta la sección [app_auth.users] en .streamlit/secrets.toml. "
            "Configura ahí los usuarios de acceso a la aplicación."
        )
    return st.secrets["app_auth"]


def verify_credentials(username: str, password: str):
    """
    Valida credenciales contra [app_auth.users] en secrets.toml.

    Returns:
        str | None: El rol del usuario si las credenciales son válidas,
                    None en caso contrario.
    """
    if not username or not password:
        return None

    auth = _get_auth_config()
    users = auth["users"]

    if username not in users:
        return None

    user_cfg = users[username]
    stored_hash = user_cfg.get("password_hash", "")
    input_hash = hash_password(password)

    if hmac.compare_digest(input_hash, stored_hash):
        return user_cfg.get("role", "consulta")

    return None


def get_allowed_pages(role: str) -> tuple:
    """Devuelve las páginas permitidas para un rol."""
    auth = _get_auth_config()
    roles = auth.get("roles", {})
    pages = roles.get(role, list(ALL_PAGES))
    return tuple(pages)


# =============================================================================
# CONTROL DE INTENTOS
# =============================================================================

def _is_locked():
    locked_until = st.session_state.get("login_locked_until")
    if not locked_until:
        return False
    if datetime.now() >= locked_until:
        st.session_state.login_locked_until = None
        return False
    return True


def _register_failed_attempt():
    attempts = st.session_state.get("login_attempts", 0) + 1
    st.session_state.login_attempts = attempts

    if attempts >= MAX_LOGIN_ATTEMPTS:
        st.session_state.login_attempts = 0
        st.session_state.login_locked_until = (
            datetime.now() + timedelta(seconds=LOCKOUT_SECONDS)
        )
        return f"Demasiados intentos. Acceso bloqueado {LOCKOUT_SECONDS} segundos."

    remaining = MAX_LOGIN_ATTEMPTS - attempts
    return f"Credenciales incorrectas. Intentos restantes: {remaining}."


# =============================================================================
# MAIN: PANTALLA DE LOGIN Y CONTROL DE SESIÓN
# =============================================================================

def _init_session_state():
    defaults = {
        "logged_in": False,
        "authenticated_user": None,
        "user_role": None,
        "login_attempts": 0,
        "login_locked_until": None,
    }
    for key, value in defaults.items():
        if key not in st.session_state:
            st.session_state[key] = value


def main():
    """
    Muestra la pantalla de login si el usuario no ha iniciado sesión.

    Si el login es exitoso, guarda usuario y rol en session_state y
    hace rerun. Si el usuario ya está autenticado, no hace nada.

    Returns:
        bool: True si el usuario está autenticado, False si se detuvo
              en la pantalla de login (st.stop ya fue llamado).
    """
    _init_session_state()

    if st.session_state.logged_in:
        return True

    # ── Pantalla de login ────────────────────────────────
    st.image(str(LOGO_PATH), width=240)
    st.title("Iniciar sesión en Almacén USSE")

    if _is_locked():
        remaining = int(
            (st.session_state.login_locked_until - datetime.now()).total_seconds()
        )
        st.warning(
            f"Acceso bloqueado. Intenta nuevamente en {max(1, remaining)} segundos."
        )
        st.stop()
        return False

    with st.form("login_form"):
        username = st.text_input("Usuario")
        password = st.text_input("Contraseña", type="password")
        submitted = st.form_submit_button("Iniciar sesión", width='stretch')

    if submitted:
        try:
            role = verify_credentials(username.strip(), password)
            if role:
                st.session_state.logged_in = True
                st.session_state.authenticated_user = username.strip()
                st.session_state.user_role = role
                st.session_state.login_attempts = 0
                st.session_state.login_locked_until = None
                st.rerun()

            st.error(_register_failed_attempt())
        except RuntimeError as e:
            st.error(str(e))

    st.stop()
    return False


def logout():
    """Cierra la sesión del usuario actual."""
    st.session_state.logged_in = False
    st.session_state.authenticated_user = None
    st.session_state.user_role = None

if __name__ == "__main__":
    print(hash_password("consul?"))