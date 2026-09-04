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
end
