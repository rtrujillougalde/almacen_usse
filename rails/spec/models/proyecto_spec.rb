require "rails_helper"

RSpec.describe Proyecto, type: :model do
  it "requires c_c, nombre_obra" do
    proyecto = build(:proyecto, c_c: nil, nombre_obra: nil)
    expect(proyecto).not_to be_valid
  end

  it "enforces unique c_c" do
    create(:proyecto, c_c: 5555)
    dup = build(:proyecto, c_c: 5555)
    expect(dup).not_to be_valid
    expect(dup.errors[:c_c]).to be_present
  end

  it "formats nombre_obra_with_cc" do
    proyecto = build(:proyecto, c_c: 12, nombre_obra: "Obra X")
    expect(proyecto.nombre_obra_with_cc).to eq("12 | Obra X")
  end
end
