require "rails_helper"

RSpec.describe Reportes::Query do
  let(:proyecto) { create(:proyecto, c_c: 3210) }

  def add_movement(tipo:, articulo:, cantidad:, moneda: nil, fecha_hora: Time.current, proyecto: self.proyecto)
    mov =
      if tipo.to_s == "compra"
        create(:movimiento, :compra, proyecto: proyecto, moneda: moneda || "MXN", fecha_hora: fecha_hora)
      else
        create(:movimiento, tipo: tipo, proyecto: proyecto, moneda: moneda, fecha_hora: fecha_hora)
      end
    attrs = { movimiento: mov, articulo: articulo, cantidad: cantidad }
    attrs[:precio_unitario] = 1 if tipo.to_s == "compra"
    create(:detalle_movimiento, **attrs)
  end

  def utilizado_row(material, moneda: "MXN", cc: 3210)
    group = described_class.utilizado_groups(cc: cc).find { |g| g[:moneda] == moneda }
    group&.[](:rows)&.find { |r| r[:material] == material }
  end

  describe ".utilizado_groups" do
    it "computes material utilizado as compra + salida - entrada and cost as precio * utilizado" do
      articulo = create(:articulo, nombre: "Cemento", tipo: :material, precio_unitario: 10)
      add_movement(tipo: :compra, articulo: articulo, cantidad: 4)
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 5)
      add_movement(tipo: :salida, articulo: articulo, cantidad: 8)

      row = utilizado_row("Cemento")
      expect(row[:total_compra]).to eq(4)
      expect(row[:total_salida]).to eq(8)
      expect(row[:total_entrada]).to eq(5)
      expect(row[:utilizado]).to eq(7)
      expect(row[:costo]).to eq(70)
    end

    it "computes herramienta utilizado as compra + salida and cost as precio * utilizado * 0.05" do
      articulo = create(:articulo, :herramienta, nombre: "Taladro", precio_unitario: 100)
      add_movement(tipo: :compra, articulo: articulo, cantidad: 3)
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 1)
      add_movement(tipo: :salida, articulo: articulo, cantidad: 2)

      row = utilizado_row("Taladro")
      expect(row[:total_compra]).to eq(3)
      expect(row[:total_salida]).to eq(2)
      expect(row[:total_entrada]).to eq(1)
      expect(row[:utilizado]).to eq(5)
      expect(row[:costo]).to eq(25.0)
    end

    it "does not add or subtract MXN and USD together" do
      articulo = create(:articulo, nombre: "Cemento", tipo: :material, precio_unitario: 10)
      add_movement(tipo: :compra, articulo: articulo, cantidad: 4, moneda: "MXN", fecha_hora: 2.days.ago)
      add_movement(tipo: :compra, articulo: articulo, cantidad: 6, moneda: "USD", fecha_hora: 1.day.ago)

      groups = described_class.utilizado_groups(cc: 3210)
      expect(groups.map { |g| g[:moneda] }).to eq(%w[MXN USD])

      mxn = utilizado_row("Cemento", moneda: "MXN")
      usd = utilizado_row("Cemento", moneda: "USD")

      expect(mxn[:total_compra]).to eq(4)
      expect(mxn[:utilizado]).to eq(4)
      expect(mxn[:costo]).to eq(40)

      expect(usd[:total_compra]).to eq(6)
      expect(usd[:utilizado]).to eq(6)
      expect(usd[:costo]).to eq(60)
    end

    it "puts entradas and salidas in the moneda of the most recent compra of that material" do
      articulo = create(:articulo, nombre: "Cemento", tipo: :material, precio_unitario: 10)
      add_movement(tipo: :compra, articulo: articulo, cantidad: 4, moneda: "MXN", fecha_hora: 3.days.ago)
      add_movement(tipo: :compra, articulo: articulo, cantidad: 6, moneda: "USD", fecha_hora: 1.day.ago)
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 1, fecha_hora: Time.current)
      add_movement(tipo: :salida, articulo: articulo, cantidad: 2, fecha_hora: Time.current)

      mxn = utilizado_row("Cemento", moneda: "MXN")
      usd = utilizado_row("Cemento", moneda: "USD")

      expect(mxn[:total_compra]).to eq(4)
      expect(mxn[:total_entrada]).to eq(0)
      expect(mxn[:total_salida]).to eq(0)
      expect(mxn[:utilizado]).to eq(4)

      expect(usd[:total_compra]).to eq(6)
      expect(usd[:total_entrada]).to eq(1)
      expect(usd[:total_salida]).to eq(2)
      expect(usd[:utilizado]).to eq(7)
      expect(usd[:costo]).to eq(70)
    end
  end

  describe ".movement_rows" do
    it "returns entrada rows for a cost center" do
      articulo = create(:articulo, nombre: "Pintura")
      add_movement(tipo: :entrada, articulo: articulo, cantidad: 4)
      rows = described_class.movement_rows(cc: 3210, movement_type: "entrada")
      expect(rows.map(&:material)).to include("Pintura")
    end

    it "filters by Mexico City calendar dates, not the UTC date" do
      articulo = create(:articulo, nombre: "Cemento nocturno")
      # 15 Mar 2026 23:30 in Mexico City is 16 Mar 05:30 UTC.
      add_movement(
        tipo: :entrada,
        articulo: articulo,
        cantidad: 2,
        fecha_hora: Time.find_zone!("Mexico City").local(2026, 3, 15, 23, 30)
      )

      included = described_class.movement_rows(
        cc: 3210, movement_type: "entrada", date_from: "2026-03-15", date_to: "2026-03-15"
      )
      excluded = described_class.movement_rows(
        cc: 3210, movement_type: "entrada", date_from: "2026-03-16", date_to: "2026-03-16"
      )

      expect(included.map(&:material)).to include("Cemento nocturno")
      expect(excluded.map(&:material)).not_to include("Cemento nocturno")
    end

    it "returns compra rows with moneda and proveedor" do
      proveedor = create(:proveedor, nombre: "Aceros Norte")
      articulo = create(:articulo, nombre: "Varilla")
      mov = create(:movimiento, :compra, proyecto: proyecto, proveedor: proveedor, moneda: "USD")
      create(:detalle_movimiento, movimiento: mov, articulo: articulo, cantidad: 6, precio_unitario: 20)

      rows = described_class.movement_rows(cc: 3210, movement_type: "compra")
      row = rows.find { |r| r.material == "Varilla" }

      expect(row).to be_present
      expect(row.cantidad.to_f).to eq(6)
      expect(row.precio_unitario.to_f).to eq(20)
      expect(row.moneda).to eq("USD")
      expect(row.proveedor).to eq("Aceros Norte")
    end
  end
end
