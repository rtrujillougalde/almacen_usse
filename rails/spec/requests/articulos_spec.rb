require "rails_helper"

RSpec.describe "Articulos", type: :request do
  let!(:articulo) { create(:articulo, nombre: "Tornillo", cantidad_en_stock: 10) }

  def punta_params(punta, overrides = {})
    {
      id_punta: punta.id_punta,
      nombre_punta: punta.nombre_punta,
      longitud: punta.longitud.to_s,
      color: punta.color
    }.merge(overrides)
  end

  describe "GET /articulos/:id/edit" do
    it "renders the form for operador" do
      sign_in_as(:operador)
      get edit_articulo_path(articulo)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tornillo")
    end

    # The page is gated on "inventario", which consulta is allowed to read, so
    # consulta reaches the edit form today.
    it "renders the form for consulta" do
      sign_in_as(:consulta)
      get edit_articulo_path(articulo)
      expect(response).to have_http_status(:ok)
    end

    it "lists only available puntas for a cable" do
      sign_in_as(:operador)
      cable = create(:articulo, :cable, cantidad_en_stock: 40)
      disponible = create(:stock_punta, articulo: cable, nombre_punta: "Punta Libre", longitud: 25.5)
      usada = create(:stock_punta, articulo: cable, nombre_punta: "Punta Usada", longitud: 10)
      salida = create(:movimiento, :salida)
      create(:detalle_movimiento, movimiento: salida, articulo: cable, stock_punta: usada, cantidad: 10)

      get edit_articulo_path(cable)
      expect(response.body).to include(disponible.nombre_punta)
      expect(response.body).not_to include(usada.nombre_punta)
    end
  end

  describe "PATCH /articulos/:id" do
    it "updates plain attributes and returns to inventario" do
      sign_in_as(:operador)

      patch articulo_path(articulo), params: {
        articulo: { nombre: "Tornillo Hex", num_catalogo: "TH-1", stock_minimo: 5 }
      }

      expect(response).to redirect_to(inventario_path)
      expect(articulo.reload.nombre).to eq("Tornillo Hex")
      expect(articulo.num_catalogo).to eq("TH-1")
      expect(articulo.stock_minimo).to eq(5)
    end

    it "rejects a blank nombre" do
      sign_in_as(:operador)

      patch articulo_path(articulo), params: { articulo: { nombre: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(articulo.reload.nombre).to eq("Tornillo")
    end

    it "refuses a stock change from a non-admin" do
      sign_in_as(:operador)

      patch articulo_path(articulo), params: {
        articulo: { nombre: articulo.nombre, cantidad_en_stock: 99 }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Solo un administrador puede cambiar stock o longitudes.")
      expect(articulo.reload.cantidad_en_stock).to eq(10)
    end

    it "lets an admin change the stock" do
      sign_in_as(:admin)

      patch articulo_path(articulo), params: {
        articulo: { nombre: articulo.nombre, cantidad_en_stock: 99 }
      }

      expect(response).to redirect_to(inventario_path)
      expect(articulo.reload.cantidad_en_stock).to eq(99)
    end

    it "refuses a punta longitud change from a non-admin" do
      sign_in_as(:operador)
      cable = create(:articulo, :cable, cantidad_en_stock: 25.5)
      punta = create(:stock_punta, articulo: cable, longitud: 25.5)

      patch articulo_path(cable), params: {
        articulo: {
          nombre: cable.nombre,
          es_cable: "1",
          cantidad_en_stock: cable.cantidad_en_stock,
          puntas: { "0" => punta_params(punta, longitud: "99") }
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(punta.reload.longitud).to eq(25.5)
      expect(cable.reload.cantidad_en_stock).to eq(25.5)
    end

    it "lets an admin change a punta longitud and rederives the cable stock" do
      sign_in_as(:admin)
      cable = create(:articulo, :cable, cantidad_en_stock: 25.5)
      punta = create(:stock_punta, articulo: cable, longitud: 25.5)

      patch articulo_path(cable), params: {
        articulo: {
          nombre: cable.nombre,
          es_cable: "1",
          cantidad_en_stock: cable.cantidad_en_stock,
          puntas: { "0" => punta_params(punta, longitud: "99") }
        }
      }

      expect(response).to redirect_to(inventario_path)
      expect(punta.reload.longitud).to eq(99)
      expect(cable.reload.cantidad_en_stock).to eq(99)
    end

    # Legacy cables carry a stock figure with no puntas behind it. Deriving
    # stock from puntas would sum to zero and destroy the figure on any edit,
    # including one that never touches stock.
    it "preserves the stock of a legacy cable that has no puntas" do
      sign_in_as(:operador)
      cable = create(:articulo, :cable, nombre: "Cable Viejo", cantidad_en_stock: 120)

      patch articulo_path(cable), params: {
        articulo: {
          nombre: "Cable Viejo MT",
          es_cable: "1",
          cantidad_en_stock: cable.cantidad_en_stock
        }
      }

      expect(response).to redirect_to(inventario_path)
      expect(cable.reload.nombre).to eq("Cable Viejo MT")
      expect(cable.cantidad_en_stock).to eq(120)
    end

    it "edits punta metadata and derives cable stock from the available puntas" do
      sign_in_as(:operador)
      cable = create(:articulo, :cable, cantidad_en_stock: 0)
      primera = create(:stock_punta, articulo: cable, longitud: 25.5, color: "negro")
      segunda = create(:stock_punta, articulo: cable, longitud: 10, color: "azul")

      patch articulo_path(cable), params: {
        articulo: {
          nombre: cable.nombre,
          es_cable: "1",
          cantidad_en_stock: cable.cantidad_en_stock,
          puntas: {
            "0" => punta_params(primera, color: "rojo"),
            "1" => punta_params(segunda)
          }
        }
      }

      expect(response).to redirect_to(inventario_path)
      expect(primera.reload.color).to eq("rojo")
      expect(cable.reload.cantidad_en_stock).to eq(35.5)
    end

    it "excludes consumed puntas when deriving cable stock" do
      sign_in_as(:operador)
      cable = create(:articulo, :cable, cantidad_en_stock: 0)
      disponible = create(:stock_punta, articulo: cable, longitud: 25.5)
      usada = create(:stock_punta, articulo: cable, longitud: 10)
      salida = create(:movimiento, :salida)
      create(:detalle_movimiento, movimiento: salida, articulo: cable, stock_punta: usada, cantidad: 10)

      patch articulo_path(cable), params: {
        articulo: {
          nombre: cable.nombre,
          es_cable: "1",
          cantidad_en_stock: cable.cantidad_en_stock,
          puntas: { "0" => punta_params(disponible) }
        }
      }

      expect(response).to redirect_to(inventario_path)
      expect(cable.reload.cantidad_en_stock).to eq(25.5)
    end
  end
end
