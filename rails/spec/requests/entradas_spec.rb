require "rails_helper"

RSpec.describe "Entradas", type: :request do
  let!(:proyecto) { create(:proyecto) }

  def cart
    session[:entrada_cart]
  end

  def add_new_item(params = {})
    post add_item_entradas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op",
      id_articulo: "__new__",
      nombre: "Item Entrada",
      tipo: "material",
      cantidad: "4",
      unidad_medida: "pza",
      categoria: "general"
    }.merge(params)
  end

  def finalize(params = {})
    post finalize_entradas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op"
    }.merge(params)
  end

  it "allows operador to register an entrada via cart flow" do
    sign_in_as(:operador)

    post start_entradas_path
    expect(response).to redirect_to(entradas_path)

    expect { add_new_item }.to change { cart["items"].size }.by(1)
    expect(response).to redirect_to(entradas_path)

    finalize
    expect(response).to redirect_to(entradas_path)
    expect(cart["pending_confirmation"]).to eq(true)

    expect {
      post entradas_path
    }.to change(Movimiento, :count).by(1)
    expect(response).to redirect_to(entradas_path)

    articulo = Articulo.find_by!(nombre: "Item Entrada")
    expect(articulo.cantidad_en_stock).to eq(4)
  end

  it "creates a new cable with its first punta" do
    sign_in_as(:operador)

    post start_entradas_path
    add_new_item(
      nombre: "Cable Nuevo",
      es_cable: "1",
      nombre_punta: "Carrete A",
      longitud: "50",
      color: "rojo",
      unidad_medida: "m",
      categoria: "cables",
      cantidad: nil
    )
    expect(cart["items"].size).to eq(1)

    finalize
    expect { post entradas_path }.to change(Movimiento, :count).by(1)

    articulo = Articulo.find_by!(nombre: "Cable Nuevo")
    expect(articulo.es_cable?).to eq(true)
    expect(articulo.cantidad_en_stock).to eq(50)

    punta = articulo.stock_puntas.sole
    expect(punta.nombre_punta).to eq("Carrete A")
    expect(punta.longitud).to eq(50)
    expect(punta.color).to eq("rojo")
    expect(Movimiento.last.detalle_movimientos.first.stock_punta).to eq(punta)
  end

  it "adds a punta to an existing cable and increments its stock" do
    sign_in_as(:operador)
    cable = create(:articulo, :cable, cantidad_en_stock: 100)

    post start_entradas_path
    post add_item_entradas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op",
      id_articulo: cable.id_articulo,
      nombre_punta: "Carrete B",
      longitud: "20",
      color: "negro"
    }
    expect(cart["items"].size).to eq(1)

    finalize
    expect { post entradas_path }.to change(Movimiento, :count).by(1)

    expect(cable.reload.cantidad_en_stock).to eq(120)
    expect(cable.stock_puntas.count).to eq(1)
    expect(cable.stock_puntas.first.longitud).to eq(20)
  end

  it "increments stock on an existing non-cable articulo" do
    sign_in_as(:operador)
    articulo = create(:articulo, cantidad_en_stock: 5)

    post start_entradas_path
    post add_item_entradas_path, params: {
      id_proyecto: proyecto.id_proyecto,
      responsable: "Op",
      id_articulo: articulo.id_articulo,
      cantidad: "3"
    }
    finalize
    post entradas_path

    expect(articulo.reload.cantidad_en_stock).to eq(8)
  end

  it "removes an item from the cart" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item

    expect {
      delete remove_item_entradas_path(index: 0)
    }.to change { cart["items"].size }.from(1).to(0)
    expect(response).to redirect_to(entradas_path)
  end

  it "empties the cart on cancel" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item

    delete cancel_entradas_path
    expect(response).to redirect_to(entradas_path)
    expect(cart["items"]).to be_empty
    expect(cart["open"]).to eq(false)
  end

  it "returns to the form when the confirmation is dismissed" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item
    finalize
    expect(cart["pending_confirmation"]).to eq(true)

    delete dismiss_confirmation_entradas_path
    expect(response).to redirect_to(entradas_path)
    expect(cart["pending_confirmation"]).to eq(false)
    expect(cart["open"]).to eq(true)
    expect(cart["items"].size).to eq(1)
  end

  it "locks the cart while a confirmation is pending" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item
    finalize

    expect(cart["pending_confirmation"]).to eq(true)
    expect(cart["open"]).to eq(false)

    expect { add_new_item }.not_to change { cart["items"].size }
    expect(response).to redirect_to(entradas_path)
    expect(flash[:alert]).to eq("Inicia una nueva entrada primero.")

    finalize
    expect(response).to redirect_to(entradas_path)
    expect(flash[:alert]).to eq("No hay una entrada en curso.")
  end

  # A failed create used to render the confirmation panel from stale ivars
  # while the cart had already dropped out of pending_confirmation, so the
  # panel's Aceptar button hit the create guard and bounced. Cancelar was the
  # only button that worked.
  it "reopens the form and allows a retry after a failed create" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item
    finalize

    allow(Movimientos::CreateEntrada).to receive(:call)
      .and_return(double(success?: false, error: "Fallo al guardar"))

    expect { post entradas_path }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Fallo al guardar")

    expect(cart["open"]).to eq(true)
    expect(cart["pending_confirmation"]).to eq(false)
    expect(cart["items"].size).to eq(1)
    expect(response.body).to include("Agregar item")
    expect(response.body).not_to include("Confirmar entrada")

    allow(Movimientos::CreateEntrada).to receive(:call).and_call_original
    finalize
    expect { post entradas_path }.to change(Movimiento, :count).by(1)
  end

  it "rejects a new item without a nombre" do
    sign_in_as(:operador)
    post start_entradas_path

    expect { add_new_item(nombre: "") }.not_to change { cart["items"].size }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Debe ingresar un nombre para el nuevo item")
  end

  it "rejects a new cable without a punta name or longitud" do
    sign_in_as(:operador)
    post start_entradas_path

    expect {
      add_new_item(nombre: "Cable Malo", es_cable: "1", nombre_punta: "", longitud: "0", cantidad: nil)
    }.not_to change { cart["items"].size }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Debe ingresar el nombre de la punta/carrete/tramo")
    expect(response.body).to include("La longitud del cable debe ser mayor a 0")
  end

  it "does not add an item before the entrada is started" do
    sign_in_as(:operador)

    expect { add_new_item }.not_to change(Articulo, :count)
    expect(response).to redirect_to(entradas_path)
    expect(cart["items"]).to be_empty
  end

  it "does not persist a movimiento when no item was added" do
    sign_in_as(:operador)
    post start_entradas_path

    expect { finalize }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cart["pending_confirmation"]).to eq(false)
  end

  it "does not persist a movimiento without a responsable" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item

    expect { finalize(responsable: "") }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cart["pending_confirmation"]).to eq(false)
  end

  it "does not persist a movimiento without a proyecto" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item

    expect { finalize(id_proyecto: "") }.not_to change(Movimiento, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(cart["pending_confirmation"]).to eq(false)
  end

  it "ignores a create without a pending confirmation" do
    sign_in_as(:operador)
    post start_entradas_path
    add_new_item

    expect { post entradas_path }.not_to change(Movimiento, :count)
    expect(response).to redirect_to(entradas_path)
  end

  it "renders recent entradas as cards with a bold cost center" do
    sign_in_as(:operador)
    articulo = create(:articulo, nombre: "Cable Reciente")
    movimiento = create(
      :movimiento,
      tipo: :entrada,
      proyecto: proyecto,
      responsable: "Ana",
      fecha_hora: Time.zone.parse("2026-09-07 15:42")
    )
    create(:detalle_movimiento, movimiento: movimiento, articulo: articulo, cantidad: 3)

    get entradas_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("movement-card")
    expect(response.body).to include("6 últimos")
    expect(response.body).to include("col-xl-4")
    expect(response.body).to include("C.C. #{proyecto.c_c}")
    expect(response.body).to include("badge-usse")
    expect(response.body).not_to include("##{movimiento.id_movimiento}")
    expect(response.body).to include(proyecto.nombre_obra)
    expect(response.body).to include("Cable Reciente")
  end

  it "forbids consulta from entradas" do
    sign_in_as(:consulta)
    get entradas_path
    expect(response).to redirect_to(inventario_path)
  end
end
