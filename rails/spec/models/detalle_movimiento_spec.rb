require "rails_helper"

RSpec.describe DetalleMovimiento, type: :model do
  it "allows nil precio_unitario on entrada details" do
    detalle = build(:detalle_movimiento, precio_unitario: nil)
    expect(detalle).to be_valid
  end

  it "requires precio_unitario greater than 0 on compra details" do
    mov = create(:movimiento, :compra)
    detalle = build(:detalle_movimiento, movimiento: mov, precio_unitario: nil)
    expect(detalle).not_to be_valid
    expect(detalle.errors[:precio_unitario]).to be_present
  end
end
