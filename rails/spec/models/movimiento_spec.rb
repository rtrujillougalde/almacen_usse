require "rails_helper"

RSpec.describe Movimiento, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:proyecto) { create(:proyecto) }
  let(:proveedor) { create(:proveedor) }

  it "accepts tipo compra" do
    mov = build(:movimiento, :compra, proyecto: proyecto, moneda: "MXN", proveedor: proveedor)
    expect(mov).to be_valid
    expect(mov.compra?).to eq(true)
  end

  it "requires proyecto, moneda, and proveedor for compra" do
    mov = build(:movimiento, :compra, proyecto: nil, moneda: nil, proveedor: nil)
    expect(mov).not_to be_valid
    expect(mov.errors[:proyecto]).to be_present
    expect(mov.errors[:moneda]).to be_present
    expect(mov.errors[:proveedor]).to be_present
  end

  it "does not require moneda or proveedor for entrada" do
    mov = build(:movimiento, tipo: :entrada, proyecto: proyecto, moneda: nil, proveedor: nil)
    expect(mov).to be_valid
  end

  it "stamps fecha_hora in Mexico City when omitted" do
    travel_to Time.utc(2026, 3, 16, 5, 30, 0) do
      mov = Movimiento.create!(tipo: :entrada, proyecto: proyecto)

      expect(mov.fecha_hora.time_zone.tzinfo.name).to eq("America/Mexico_City")
      expect(mov.fecha_hora.strftime("%Y-%m-%d %H:%M")).to eq("2026-03-15 23:30")
    end
  end

  it "rejects unknown moneda on compra" do
    mov = build(:movimiento, :compra, proyecto: proyecto, moneda: "EUR", proveedor: proveedor)
    expect(mov).not_to be_valid
    expect(mov.errors[:moneda]).to be_present
  end
end
