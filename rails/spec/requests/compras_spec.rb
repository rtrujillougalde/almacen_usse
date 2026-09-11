require "rails_helper"

RSpec.describe "Compras", type: :request do
  let!(:proyecto) { create(:proyecto) }
  let!(:proveedor) { create(:proveedor) }

  def start_compra
    post start_compras_path
  end

  def finalize_compra(params = {})
    post finalize_compras_path, params: {
      id_proyecto: proyecto.id_proyecto,
      moneda: "MXN",
      id_proveedor: proveedor.id_proveedor,
      responsable: "Op"
    }.merge(params)
  end

  def add_new_item(precio_unitario: "7.5")
    post add_item_compras_path, params: {
      id_proyecto: proyecto.id_proyecto,
      moneda: "MXN",
      id_proveedor: proveedor.id_proveedor,
      responsable: "Op",
      id_articulo: "__new__",
      nombre: "Item Compra",
      tipo: "material",
      cantidad: "4",
      unidad_medida: "pza",
      categoria: "general",
      precio_unitario: precio_unitario
    }
  end

  it "allows operador to open compras" do
    sign_in_as(:operador)
    get compras_path
    expect(response).to have_http_status(:ok)
  end

  it "allows operador to register a compra via cart flow" do
    sign_in_as(:operador)
    start_compra
    expect(response).to redirect_to(compras_path)

    expect { add_new_item }.to change { session[:compra_cart]["items"].size }.by(1)
    expect(response).to redirect_to(compras_path)

    post finalize_compras_path, params: {
      id_proyecto: proyecto.id_proyecto,
      moneda: "MXN",
      id_proveedor: proveedor.id_proveedor,
      responsable: "Op"
    }
    expect(response).to redirect_to(compras_path)
    expect(session[:compra_cart]["pending_confirmation"]).to eq(true)

    expect { post compras_path }.to change(Movimiento, :count).by(1)
    expect(response).to redirect_to(compras_path)

    movimiento = Movimiento.last
    expect(movimiento.compra?).to eq(true)
    expect(movimiento.moneda).to eq("MXN")
    expect(movimiento.proveedor).to eq(proveedor)

    articulo = Articulo.find_by!(nombre: "Item Compra")
    expect(articulo.precio_unitario).to eq(7.5)
    expect(articulo.cantidad_en_stock).to eq(4)
    expect(movimiento.detalle_movimientos.first.precio_unitario).to eq(7.5)
  end

  it "updates precio_unitario on an existing article" do
    sign_in_as(:operador)
    articulo = create(:articulo, cantidad_en_stock: 5, precio_unitario: 100)

    start_compra
    post add_item_compras_path, params: {
      id_proyecto: proyecto.id_proyecto,
      moneda: "USD",
      id_proveedor: proveedor.id_proveedor,
      responsable: "Op",
      id_articulo: articulo.id_articulo,
      cantidad: "3",
      precio_unitario: "12.25"
    }
    post finalize_compras_path, params: {
      id_proyecto: proyecto.id_proyecto,
      moneda: "USD",
      id_proveedor: proveedor.id_proveedor,
      responsable: "Op"
    }
    post compras_path

    articulo.reload
    expect(articulo.cantidad_en_stock).to eq(8)
    expect(articulo.precio_unitario).to eq(12.25)
    expect(Movimiento.last.detalle_movimientos.first.precio_unitario).to eq(12.25)
  end

  it "does not add an item without precio_unitario" do
    sign_in_as(:operador)
    start_compra

    expect { add_new_item(precio_unitario: "") }.not_to change { session[:compra_cart]["items"].size }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Precio unitario es obligatorio")
  end

  it "returns a specific error and does not persist when header fields are missing" do
    sign_in_as(:operador)
    start_compra
    add_new_item

    expect {
      post finalize_compras_path, params: { responsable: "Op" }
    }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Proyecto es obligatorio")
  end

  it "locks the cart while a confirmation is pending" do
    sign_in_as(:operador)
    start_compra
    add_new_item
    finalize_compra

    expect(session[:compra_cart]["pending_confirmation"]).to eq(true)
    expect(session[:compra_cart]["open"]).to eq(false)

    expect { add_new_item }.not_to change { session[:compra_cart]["items"].size }
    expect(response).to redirect_to(compras_path)
    expect(flash[:alert]).to eq("Inicia una nueva compra primero.")

    finalize_compra
    expect(response).to redirect_to(compras_path)
    expect(flash[:alert]).to eq("No hay una compra en curso.")
  end

  # A failed create used to render the confirmation panel from stale ivars
  # while the cart had already dropped out of pending_confirmation, so the
  # panel's Aceptar button hit the create guard and bounced. Cancelar was the
  # only button that worked.
  it "reopens the form and allows a retry after a failed create" do
    sign_in_as(:operador)
    start_compra
    add_new_item
    finalize_compra

    allow(Movimientos::CreateCompra).to receive(:call)
      .and_return(double(success?: false, error: "Fallo al guardar"))

    expect { post compras_path }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Fallo al guardar")

    expect(session[:compra_cart]["open"]).to eq(true)
    expect(session[:compra_cart]["pending_confirmation"]).to eq(false)
    expect(session[:compra_cart]["items"].size).to eq(1)
    expect(response.body).to include("Agregar item")
    expect(response.body).not_to include("Confirmar compra")

    allow(Movimientos::CreateCompra).to receive(:call).and_call_original
    finalize_compra
    expect { post compras_path }.to change(Movimiento, :count).by(1)
  end

  # Compras never checked the responsable, so a compra could be recorded with
  # nobody accountable for it. Entradas and salidas both required it.
  it "requires a responsable before finalizing" do
    sign_in_as(:operador)
    start_compra
    add_new_item

    expect { finalize_compra(responsable: "") }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Responsable es obligatorio")
    expect(session[:compra_cart]["pending_confirmation"]).to eq(false)
  end

  it "shows precio unitario in recent compras" do
    sign_in_as(:operador)
    movimiento = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "USD")
    articulo = create(:articulo, nombre: "Item Reciente")
    create(:detalle_movimiento, movimiento: movimiento, articulo: articulo, cantidad: 2, precio_unitario: 15.5)

    get compras_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Precio")
    expect(response.body).to include("Item Reciente")
    expect(response.body).to include("$15.50 USD")
    expect(response.body).to include("C.C. #{proyecto.c_c}")
    expect(response.body).to include(proveedor.nombre)
  end

  it "forbids consulta from compras" do
    sign_in_as(:consulta)
    get compras_path
    expect(response).to redirect_to(inventario_path)
  end
end
