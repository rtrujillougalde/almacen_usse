require "rails_helper"

RSpec.describe "Salidas", type: :request do
  let!(:proyecto) { create(:proyecto) }
  let!(:articulo) { create(:articulo, cantidad_en_stock: 8) }

  def cart
    session[:salida_cart]
  end

  def add_item(params = {})
    post add_item_salidas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op",
      id_articulo: articulo.id_articulo,
      cantidad: "2"
    }.merge(params)
  end

  def finalize(params = {})
    post finalize_salidas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op"
    }.merge(params)
  end

  it "allows operador to open salidas" do
    sign_in_as(:operador)
    get salidas_path
    expect(response).to have_http_status(:ok)
  end

  it "allows operador to register a salida via cart flow" do
    sign_in_as(:operador)

    post start_salidas_path
    expect(response).to redirect_to(salidas_path)

    add_item
    expect(response).to redirect_to(salidas_path)
    expect(cart["items"].size).to eq(1)

    finalize
    expect(cart["pending_confirmation"]).to eq(true)

    expect {
      post salidas_path
    }.to change(Movimiento.where(tipo: :salida), :count).by(1)
    expect(response).to redirect_to(salidas_path)
    expect(articulo.reload.cantidad_en_stock).to eq(6)
  end

  it "registers a cable salida by consuming a whole punta" do
    sign_in_as(:operador)
    cable = create(:articulo, :cable, cantidad_en_stock: 30)
    punta = create(:stock_punta, articulo: cable, longitud: 12)

    post start_salidas_path
    add_item(id_articulo: cable.id_articulo, id_punta: punta.id_punta, cantidad: nil)
    expect(cart["items"].size).to eq(1)

    finalize
    expect { post salidas_path }.to change(Movimiento.where(tipo: :salida), :count).by(1)

    expect(cable.reload.cantidad_en_stock).to eq(18)
    expect(StockPunta.available).not_to include(punta)

    detalle = Movimiento.where(tipo: :salida).last.detalle_movimientos.first
    expect(detalle.stock_punta).to eq(punta)
    expect(detalle.cantidad).to eq(12)
  end

  it "removes an item from the cart" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item

    expect {
      delete remove_item_salidas_path(index: 0)
    }.to change { cart["items"].size }.from(1).to(0)
    expect(response).to redirect_to(salidas_path)
  end

  it "empties the cart on cancel" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item

    delete cancel_salidas_path
    expect(response).to redirect_to(salidas_path)
    expect(cart["items"]).to be_empty
    expect(cart["open"]).to eq(false)
  end

  it "returns to the form when the confirmation is dismissed" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item
    finalize
    expect(cart["pending_confirmation"]).to eq(true)

    delete dismiss_confirmation_salidas_path
    expect(response).to redirect_to(salidas_path)
    expect(cart["pending_confirmation"]).to eq(false)
    expect(cart["open"]).to eq(true)
    expect(cart["items"].size).to eq(1)
  end

  it "locks the cart while a confirmation is pending" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item
    finalize

    expect(cart["pending_confirmation"]).to eq(true)
    expect(cart["open"]).to eq(false)

    expect { add_item }.not_to change { cart["items"].size }
    expect(response).to redirect_to(salidas_path)
    expect(flash[:alert]).to eq("Inicia una nueva salida primero.")

    finalize
    expect(response).to redirect_to(salidas_path)
    expect(flash[:alert]).to eq("No hay una salida en curso.")
  end

  # A failed create used to render the confirmation panel from stale ivars
  # while the cart had already dropped out of pending_confirmation, so the
  # panel's Aceptar button hit the create guard and bounced. Cancelar was the
  # only button that worked.
  it "reopens the form and allows a retry after a failed create" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item
    finalize

    allow(Movimientos::CreateSalida).to receive(:call)
      .and_return(double(success?: false, error: "Sin stock suficiente"))

    expect { post salidas_path }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Sin stock suficiente")

    expect(cart["open"]).to eq(true)
    expect(cart["pending_confirmation"]).to eq(false)
    expect(cart["items"].size).to eq(1)
    expect(response.body).to include("Agregar item")
    expect(response.body).not_to include("Confirmar salida")

    allow(Movimientos::CreateSalida).to receive(:call).and_call_original
    finalize
    expect { post salidas_path }.to change(Movimiento.where(tipo: :salida), :count).by(1)
  end

  # Settles the guard order: an empty cart is reported before missing header
  # fields, matching entradas and compras. Salidas used to check the
  # responsable first.
  it "checks items before the header fields" do
    sign_in_as(:operador)
    post start_salidas_path

    finalize(responsable: "", id_proyecto: "")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Debe agregar al menos un item")
  end

  # Proyecto.find raised RecordNotFound here, so a proyecto deleted mid-cart
  # produced a 500 rather than a message the user could act on.
  it "reports a missing proyecto instead of raising when it disappears mid-cart" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item
    finalize
    proyecto.destroy!

    expect { post salidas_path }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Proyecto es obligatorio")
  end

  it "rejects a quantity above available stock" do
    sign_in_as(:operador)
    post start_salidas_path

    expect { add_item(cantidad: "99") }.not_to change { cart["items"].size }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("No hay suficiente stock")
  end

  it "rejects the same punta twice in one salida" do
    sign_in_as(:operador)
    cable = create(:articulo, :cable, cantidad_en_stock: 30)
    punta = create(:stock_punta, articulo: cable, longitud: 12)

    post start_salidas_path
    add_item(id_articulo: cable.id_articulo, id_punta: punta.id_punta, cantidad: nil)

    expect {
      add_item(id_articulo: cable.id_articulo, id_punta: punta.id_punta, cantidad: nil)
    }.not_to change { cart["items"].size }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Esa punta ya está en la salida actual")
  end

  it "rejects a punta already consumed by another salida" do
    sign_in_as(:operador)
    cable = create(:articulo, :cable, cantidad_en_stock: 30)
    punta = create(:stock_punta, articulo: cable, longitud: 12)
    consumida = create(:movimiento, :salida, proyecto: proyecto)
    create(:detalle_movimiento, movimiento: consumida, articulo: cable, stock_punta: punta, cantidad: 12)

    post start_salidas_path
    expect {
      add_item(id_articulo: cable.id_articulo, id_punta: punta.id_punta, cantidad: nil)
    }.not_to change { cart["items"].size }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Punta ya utilizada en una salida")
  end

  it "does not add an item before the salida is started" do
    sign_in_as(:operador)

    expect { add_item }.not_to change(DetalleMovimiento, :count)
    expect(response).to redirect_to(salidas_path)
    expect(cart["items"]).to be_empty
  end

  it "does not persist a movimiento when no item was added" do
    sign_in_as(:operador)
    post start_salidas_path

    expect { finalize }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cart["pending_confirmation"]).to eq(false)
  end

  it "does not persist a movimiento without a responsable" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item

    expect { finalize(responsable: "") }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cart["pending_confirmation"]).to eq(false)
  end

  it "does not persist a movimiento without a proyecto" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item

    expect { finalize(id_proyecto: "") }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cart["pending_confirmation"]).to eq(false)
  end

  it "ignores a create without a pending confirmation" do
    sign_in_as(:operador)
    post start_salidas_path
    add_item

    expect { post salidas_path }.not_to change(Movimiento, :count)
    expect(response).to redirect_to(salidas_path)
  end

  it "renders recent salidas" do
    sign_in_as(:operador)
    movimiento = create(:movimiento, :salida, proyecto: proyecto, responsable: "Ana")
    create(:detalle_movimiento, movimiento: movimiento, articulo: articulo, cantidad: 3)

    get salidas_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(articulo.nombre)
    expect(response.body).to include("C.C. #{proyecto.c_c}")
  end

  it "forbids consulta from salidas" do
    sign_in_as(:consulta)
    get salidas_path
    expect(response).to redirect_to(inventario_path)
  end
end
