require "rails_helper"

RSpec.describe Proveedor, type: :model do
  it "requires nombre" do
    proveedor = build(:proveedor, nombre: nil)
    expect(proveedor).not_to be_valid
    expect(proveedor.errors[:nombre]).to be_present
  end

  it "assigns id_proveedor on create" do
    proveedor = create(:proveedor)
    expect(proveedor.id_proveedor).to be_present
  end

  it "accepts an offered delivery minimum including zero" do
    zero = build(:proveedor, entrega_estado: "ofrecida", entrega_monto_minimo: 0, entrega_moneda: "USD")
    expect(zero).to be_valid

    missing = build(:proveedor, entrega_estado: "ofrecida", entrega_monto_minimo: nil, entrega_moneda: nil)
    expect(missing).not_to be_valid
    expect(missing.errors[:entrega_monto_minimo]).to be_present
    expect(missing.errors[:entrega_moneda]).to be_present
  end

  it "rejects a negative minimum and an unknown currency" do
    negative = build(:proveedor, entrega_estado: "ofrecida", entrega_monto_minimo: -1, entrega_moneda: "MXN")
    expect(negative).not_to be_valid
    expect(negative.errors[:entrega_monto_minimo]).to be_present

    bad_currency = build(:proveedor, entrega_estado: "ofrecida", entrega_monto_minimo: 10, entrega_moneda: "EUR")
    expect(bad_currency).not_to be_valid
    expect(bad_currency.errors[:entrega_moneda]).to be_present
  end

  it "clears amount and currency when delivery is no longer offered" do
    proveedor = create(:proveedor, entrega_estado: "ofrecida", entrega_monto_minimo: 1500, entrega_moneda: "MXN")

    proveedor.update!(entrega_estado: "no_ofrecida")

    expect(proveedor.entrega_monto_minimo).to be_nil
    expect(proveedor.entrega_moneda).to be_nil
    expect(proveedor.entrega_resumen).to eq("No ofrece")
  end
end
