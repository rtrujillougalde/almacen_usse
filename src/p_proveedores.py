import streamlit as st

from data import (
    add_proveedor,
    get_proveedores_for_edit,
    get_proveedores_table_data,
    update_proveedor,
)


@st.dialog("Editar proveedor")
def editar_proveedor_dialog(proveedor):
    with st.form("form_editar_proveedor"):
        nombre = st.text_input("Nombre *", value=proveedor.get("nombre") or "")
        telefono = st.text_input("Teléfono", value=proveedor.get("telefono") or "")
        email = st.text_input("Email", value=proveedor.get("email") or "")
        pagina_web = st.text_input("Página web", value=proveedor.get("pagina_web") or "")
        direccion = st.text_area("Dirección", value=proveedor.get("direccion") or "")
        contacto = st.text_input("Contacto", value=proveedor.get("contacto") or "")
        notas = st.text_area("Notas", value=proveedor.get("notas") or "")

        submitted = st.form_submit_button("Guardar cambios")

        if submitted:
            if nombre.strip():
                try:
                    update_proveedor(
                        id_proveedor=proveedor["id_proveedor"],
                        nombre=nombre,
                        telefono=telefono,
                        email=email,
                        pagina_web=pagina_web,
                        direccion=direccion,
                        contacto=contacto,
                        notas=notas,
                    )
                    st.success("Proveedor actualizado exitosamente.")
                    st.rerun()
                except Exception as e:
                    st.error(f"Error al actualizar proveedor: {e}")
            else:
                st.error("El campo Nombre es obligatorio.")

def main():
    st.title("Gestión de Proveedores")
    st.write("Aquí puedes gestionar tus proveedores, agregar nuevos, editar información existente y eliminar proveedores que ya no necesites.")

    # Tabla de proveedores existentes
    proveedores_data = get_proveedores_table_data()
    st.subheader("Proveedores registrados")
    if proveedores_data:
        st.dataframe(proveedores_data, use_container_width=True, hide_index=True)

        proveedores_edit_data = get_proveedores_for_edit()
        if proveedores_edit_data:
            opciones = {
                f"{p['id_proveedor']} - {p['nombre']}": p
                for p in proveedores_edit_data
            }
            seleccionado = st.selectbox(
                "Proveedor a editar",
                options=list(opciones.keys()),
                key="proveedor_editar_select",
            )

            if st.button("✏️ Editar proveedor seleccionado"):
                editar_proveedor_dialog(opciones[seleccionado])
    else:
        st.info("Aún no hay proveedores registrados.")

    # Inicializar estado de visibilidad del formulario
    if "mostrar_form_proveedor" not in st.session_state:
        st.session_state.mostrar_form_proveedor = False

    # Botón para alternar visibilidad del formulario
    if st.button("➕ Añadir Proveedor"):
        st.session_state.mostrar_form_proveedor = (
            not st.session_state.mostrar_form_proveedor
        )
        st.rerun()

    st.divider()

    # Mostrar formulario solo si el botón fue presionado
    if st.session_state.mostrar_form_proveedor:
        with st.form("form_proveedor"):
            nombre = st.text_input("Nombre *")
            telefono = st.text_input("Teléfono")
            email = st.text_input("Email")
            pagina_web = st.text_input("Página web")
            direccion = st.text_area("Dirección")
            contacto = st.text_input("Contacto")
            notas = st.text_area("Notas")

            submitted = st.form_submit_button("Guardar Proveedor")

            if submitted:
                if nombre.strip():
                    try:
                        add_proveedor(
                            nombre=nombre,
                            telefono=telefono,
                            email=email,
                            pagina_web=pagina_web,
                            direccion=direccion,
                            contacto=contacto,
                            notas=notas
                        )
                        st.success(f"Proveedor '{nombre.strip()}' agregado exitosamente.")
                        st.session_state.mostrar_form_proveedor = False
                        st.rerun()
                    except Exception as e:
                        st.error(f"Error al agregar proveedor: {e}")
                else:
                    st.error("El campo Nombre es obligatorio.")