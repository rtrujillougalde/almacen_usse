require "rails_helper"

# Unit coverage for every validation branch the movement carts can hit. The
# request specs drive these through the controllers; this file pins the
# messages and the resulting item shape directly.
RSpec.describe "Movimientos cart item builders" do
  def params_for(attributes = {})
    ActionController::Parameters.new(attributes)
  end

  def build(builder, cart_items: [], **attributes)
    builder.call(params_for(attributes), cart_items: cart_items)
  end

  describe Movimientos::StockIncreaseItemBuilder do
    it "rejects a blank selection" do
      item, error = build(described_class)

      expect(item).to be_nil
      expect(error).to eq("Debe seleccionar un item")
    end

    it "rejects an unknown articulo" do
      item, error = build(described_class, id_articulo: "999999")

      expect(item).to be_nil
      expect(error).to eq("Artículo no encontrado")
    end

    context "with a new item" do
      it "requires a nombre" do
        item, error = build(described_class, id_articulo: "__new__", nombre: "  ", cantidad: "3")

        expect(item).to be_nil
        expect(error).to eq("Debe ingresar un nombre para el nuevo item")
      end

      it "requires a positive cantidad when it is not a cable" do
        item, error = build(described_class, id_articulo: "__new__", nombre: "Tornillo", cantidad: "0")

        expect(item).to be_nil
        expect(error).to eq("La cantidad debe ser mayor a 0")
      end

      it "joins every cable error into one message" do
        item, error = build(described_class,
          id_articulo: "__new__", nombre: "Cable", es_cable: "1", nombre_punta: " ", longitud: "0")

        expect(item).to be_nil
        expect(error).to eq(
          "Debe ingresar el nombre de la punta/carrete/tramo. La longitud del cable debe ser mayor a 0"
        )
      end

      it "builds a cable item measured by its longitud" do
        item, error = build(described_class,
          id_articulo: "__new__", nombre: "Cable", es_cable: "1",
          nombre_punta: "Carrete 1", longitud: "25.5", color: "rojo")

        expect(error).to be_nil
        expect(item.to_h).to include(
          "is_new" => true, "nombre" => "Cable", "nombre_item" => "Cable",
          "es_cable" => true, "longitud" => 25.5, "color" => "rojo", "tipo" => "material"
        )
      end

      it "drops the color of a non-cable item" do
        item, = build(described_class,
          id_articulo: "__new__", nombre: "Tornillo", es_cable: "0", cantidad: "4", color: "rojo")

        expect(item.to_h).to include("es_cable" => false, "cantidad" => 4.0, "color" => nil)
      end
    end

    context "with an existing articulo" do
      it "requires punta details for a cable" do
        cable = create(:articulo, :cable)

        item, error = build(described_class, id_articulo: cable.id_articulo, longitud: "0")

        expect(item).to be_nil
        expect(error).to eq(
          "Debe ingresar el nombre de la punta/carrete/tramo. La longitud del cable debe ser mayor a 0"
        )
      end

      it "builds a cable item carrying the new punta" do
        cable = create(:articulo, :cable, nombre: "Cable Cobre")

        item, error = build(described_class,
          id_articulo: cable.id_articulo, nombre_punta: "Carrete 2", longitud: "20", color: "azul")

        expect(error).to be_nil
        expect(item.to_h).to include(
          "is_new" => false, "id_articulo" => cable.id_articulo, "nombre_item" => "Cable Cobre",
          "es_cable" => true, "nombre_punta" => "Carrete 2", "longitud" => 20.0, "cantidad" => 0
        )
      end

      it "requires a positive cantidad for a non-cable" do
        articulo = create(:articulo)

        item, error = build(described_class, id_articulo: articulo.id_articulo, cantidad: "0")

        expect(item).to be_nil
        expect(error).to eq("La cantidad debe ser mayor a 0")
      end

      it "builds a non-cable item" do
        articulo = create(:articulo, nombre: "Guantes")

        item, error = build(described_class, id_articulo: articulo.id_articulo, cantidad: "6")

        expect(error).to be_nil
        expect(item.to_h).to include(
          "is_new" => false, "nombre_item" => "Guantes", "es_cable" => false, "cantidad" => 6.0
        )
      end
    end

    it "accepts a missing precio, since an entrada records no money" do
      item, error = build(described_class, id_articulo: "__new__", nombre: "Tornillo", cantidad: "2")

      expect(error).to be_nil
      expect(item.to_h["precio_unitario"]).to be_nil
    end
  end

  describe Movimientos::CompraItemBuilder do
    it "rejects a missing precio before anything else about the item" do
      item, error = build(described_class, id_articulo: "")

      expect(item).to be_nil
      expect(error).to eq("Precio unitario es obligatorio")
    end

    it "rejects a precio of zero" do
      item, error = build(described_class,
        id_articulo: "__new__", nombre: "Tornillo", cantidad: "2", precio_unitario: "0")

      expect(item).to be_nil
      expect(error).to eq("Precio unitario es obligatorio")
    end

    it "keeps the precio on the item" do
      item, error = build(described_class,
        id_articulo: "__new__", nombre: "Taladro", cantidad: "2", precio_unitario: "1250.50")

      expect(error).to be_nil
      expect(item.to_h["precio_unitario"]).to eq("1250.50")
    end
  end

  describe Movimientos::SalidaItemBuilder do
    let(:cable) { create(:articulo, :cable, nombre: "Cable Cobre", cantidad_en_stock: 30) }
    let(:punta) { create(:stock_punta, articulo: cable, nombre_punta: "Carrete 3", longitud: 12) }

    it "rejects a blank selection" do
      item, error = build(described_class)

      expect(item).to be_nil
      expect(error).to eq("Debe seleccionar un item")
    end

    it "rejects an unknown articulo" do
      item, error = build(described_class, id_articulo: "999999")

      expect(item).to be_nil
      expect(error).to eq("Artículo no encontrado")
    end

    it "requires a punta for a cable" do
      item, error = build(described_class, id_articulo: cable.id_articulo)

      expect(item).to be_nil
      expect(error).to eq("Debe seleccionar una punta/carrete/tramo")
    end

    it "rejects an unknown punta" do
      item, error = build(described_class, id_articulo: cable.id_articulo, id_punta: "999999")

      expect(item).to be_nil
      expect(error).to eq("Punta no encontrada")
    end

    it "rejects a punta belonging to another articulo" do
      otro = create(:articulo, :cable)
      ajena = create(:stock_punta, articulo: otro)

      item, error = build(described_class, id_articulo: cable.id_articulo, id_punta: ajena.id_punta)

      expect(item).to be_nil
      expect(error).to eq("Punta no pertenece al artículo")
    end

    it "rejects a punta already consumed by a saved salida" do
      salida = create(:movimiento, :salida)
      create(:detalle_movimiento, movimiento: salida, articulo: cable, stock_punta: punta, cantidad: 12)

      item, error = build(described_class, id_articulo: cable.id_articulo, id_punta: punta.id_punta)

      expect(item).to be_nil
      expect(error).to eq("Punta ya utilizada en una salida")
    end

    it "rejects a punta already sitting in the current cart" do
      cart_items = [ { "id_punta" => punta.id_punta } ]

      item, error = build(described_class,
        id_articulo: cable.id_articulo, id_punta: punta.id_punta, cart_items: cart_items)

      expect(item).to be_nil
      expect(error).to eq("Esa punta ya está en la salida actual")
    end

    it "builds a cable item measured by the punta longitud" do
      item, error = build(described_class, id_articulo: cable.id_articulo, id_punta: punta.id_punta)

      expect(error).to be_nil
      expect(item.to_h).to include(
        "id_articulo" => cable.id_articulo, "es_cable" => true, "cantidad" => 0,
        "id_punta" => punta.id_punta, "nombre_punta" => "Carrete 3", "longitud" => 12.0
      )
    end

    it "rejects a non-positive cantidad" do
      articulo = create(:articulo, cantidad_en_stock: 8)

      item, error = build(described_class, id_articulo: articulo.id_articulo, cantidad: "0")

      expect(item).to be_nil
      expect(error).to eq("La cantidad debe ser mayor a 0")
    end

    it "rejects a cantidad above stock and names what is available" do
      articulo = create(:articulo, cantidad_en_stock: 8)

      item, error = build(described_class, id_articulo: articulo.id_articulo, cantidad: "99")

      expect(item).to be_nil
      expect(error).to eq("No hay suficiente stock (disponible: 8.0)")
    end

    it "builds a non-cable item" do
      articulo = create(:articulo, nombre: "Guantes", cantidad_en_stock: 8)

      item, error = build(described_class, id_articulo: articulo.id_articulo, cantidad: "2")

      expect(error).to be_nil
      expect(item.to_h).to include(
        "nombre_item" => "Guantes", "es_cable" => false, "cantidad" => 2.0, "id_punta" => nil
      )
    end
  end

  describe Movimientos::CartItem do
    it "hands the service its own nombre when the item is new" do
      args = described_class.new("nombre" => "Cable", "nombre_item" => "Cable", "cantidad" => 3).to_service_args

      expect(args[:nombre]).to eq("Cable")
      expect(args[:cantidad]).to eq(3)
    end

    it "falls back to the display name for an existing articulo" do
      args = described_class.new("nombre_item" => "Guantes", "id_articulo" => 7).to_service_args

      expect(args[:nombre]).to eq("Guantes")
      expect(args[:id_articulo]).to eq(7)
    end
  end
end
