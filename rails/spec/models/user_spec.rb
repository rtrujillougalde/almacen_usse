require "rails_helper"

RSpec.describe User do
  describe "#can_access?" do
    it "lets an admin reach every staff page" do
      user = build(:user, :admin)

      User::STAFF_PAGES.each { |page| expect(user).to be_can_access(page) }
    end

    it "gives operador exactly the same pages as admin" do
      expect(build(:user, :operador).allowed_pages).to eq(build(:user, :admin).allowed_pages)
    end

    it "limits consulta to inventario and reportes" do
      user = build(:user, :consulta)

      expect(user.allowed_pages).to eq(%w[inventario reportes])
      expect(user).not_to be_can_access("entradas")
      expect(user).not_to be_can_access("proveedores")
    end
  end

  describe "#first_allowed_page" do
    it "falls back to inventario when a role maps to nothing" do
      user = build(:user, :consulta)
      allow(user).to receive(:allowed_pages).and_return([])

      expect(user.first_allowed_page).to eq("inventario")
    end
  end
end
