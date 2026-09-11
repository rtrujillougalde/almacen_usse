require "rails_helper"

RSpec.describe "Inventario", type: :request do
  before { sign_in_as(:admin) }

  describe "GET /inventario" do
    it "filters by nombre" do
      create(:articulo, nombre: "Cable Rojo")
      create(:articulo, nombre: "Tornillo")
      get inventario_path, params: { nombre: "cable" }
      expect(response.body).to include("Cable Rojo")
      expect(response.body).not_to include("Tornillo")
    end

    it "filters by tipo" do
      create(:articulo, nombre: "Mat A", tipo: :material)
      create(:articulo, :herramienta, nombre: "Herr B")
      get inventario_path, params: { tipo: "herramienta" }
      expect(response.body).to include("Herr B")
      expect(response.body).not_to include("Mat A")
    end

    it "highlights low stock rows" do
      create(:articulo, nombre: "Bajo Stock", cantidad_en_stock: 1, stock_minimo: 10)
      get inventario_path
      expect(response.body).to include("table-warning")
      expect(response.body).to include("Bajo Stock")
    end
  end

  describe "PATCH /articulos/:id" do
    let!(:articulo) { create(:articulo, cantidad_en_stock: 5, stock_minimo: 1) }

    it "updates proveedor by id without AssociationTypeMismatch" do
      other = create(:proveedor, nombre: "Otro Prov")
      patch articulo_path(articulo), params: {
        articulo: {
          nombre: articulo.nombre,
          tipo: articulo.tipo,
          stock_minimo: articulo.stock_minimo,
          unidad_medida: articulo.unidad_medida,
          cantidad_en_stock: articulo.cantidad_en_stock,
          proveedor: other.id_proveedor
        }
      }
      expect(response).to redirect_to(inventario_path)
      expect(articulo.reload.proveedor).to eq(other.id_proveedor)
      expect(articulo.proveedor_record).to eq(other)
    end

    it "updates stock as an admin" do
      patch articulo_path(articulo), params: {
        articulo: {
          nombre: articulo.nombre,
          cantidad_en_stock: 9,
          tipo: articulo.tipo,
          stock_minimo: articulo.stock_minimo,
          unidad_medida: articulo.unidad_medida
        }
      }
      expect(response).to redirect_to(inventario_path)
      expect(articulo.reload.cantidad_en_stock).to eq(9)
    end

    it "recalculates cable stock from available puntas after length change" do
      cable = create(:articulo, :cable, cantidad_en_stock: 10)
      punta = create(:stock_punta, articulo: cable, longitud: 10, nombre_punta: "P1")

      patch articulo_path(cable), params: {
        articulo: {
          nombre: cable.nombre,
          tipo: cable.tipo,
          es_cable: "1",
          puntas: {
            "0" => { id_punta: punta.id_punta, nombre_punta: "P1", longitud: 40, color: "rojo" }
          }
        }
      }

      expect(response).to redirect_to(inventario_path)
      expect(punta.reload.longitud).to eq(40)
      expect(cable.reload.cantidad_en_stock).to eq(40)
    end
  end
end
