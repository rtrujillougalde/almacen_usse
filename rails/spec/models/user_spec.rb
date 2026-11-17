require "rails_helper"

RSpec.describe User do
  describe "#can_access?" do
    it "lets an admin reach every staff page" do
      user = build(:user, :admin)

      User::STAFF_PAGES.each { |page| expect(user).to be_can_access(page) }
    end

    it "lets an admin reach usuarios" do
      expect(build(:user, :admin)).to be_can_access("usuarios")
    end

    it "gives operador the same staff pages as admin, but not usuarios" do
      operador = build(:user, :operador)

      expect(operador.allowed_pages).to eq(User::STAFF_PAGES)
      expect(operador).not_to be_can_access("usuarios")
    end

    it "blocks warehouse pages without almacen access" do
      user = build(:user, :admin, :solo_personal)

      expect(user.enters?(:personal)).to be(true)
      expect(user.enters?(:almacen)).to be(false)
      expect(user).not_to be_can_access("inventario")
      expect(user.allowed_pages).to eq([])
    end

    it "lets ambos enter both systems" do
      user = build(:user, acceso: :ambos)

      expect(user.enters?(:almacen)).to be(true)
      expect(user.enters?(:personal)).to be(true)
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

  describe "validations" do
    it "requires first and last name" do
      user = build(:user, first_name: "", last_name: nil)

      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to be_present
      expect(user.errors[:last_name]).to be_present
    end

    it "builds the full name" do
      expect(build(:user, first_name: "Ana", last_name: "López").full_name).to eq("Ana López")
    end
  end

  describe "#active_for_authentication?" do
    it "is false for a deactivated account" do
      expect(build(:user, :inactive)).not_to be_active_for_authentication
    end

    it "is true for an active account" do
      expect(build(:user)).to be_active_for_authentication
    end
  end

  describe "keeping one active admin" do
    it "blocks deactivating the only active admin" do
      admin = create(:user, :admin)

      expect(admin.update(active: false)).to be(false)
      expect(admin.errors[:base]).to be_present
      expect(admin.reload).to be_active
    end

    it "blocks demoting the only active admin" do
      admin = create(:user, :admin)

      expect(admin.update(role: :consulta)).to be(false)
    end

    it "allows deactivating an admin when another active admin exists" do
      admin = create(:user, :admin)
      create(:user, :admin)

      expect(admin.update(active: false)).to be(true)
    end
  end
end
