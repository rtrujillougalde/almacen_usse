require "rails_helper"

# Guards the Stimulus controllers that reveal and enable the item fields.
# Request specs cannot see this: every one of these inputs ships disabled and
# inside a d-none wrapper, and only JavaScript turns them on.
RSpec.describe "Item form toggles", type: :system do
  let!(:proyecto) { create(:proyecto) }

  describe "entrada form" do
    let!(:cable) { create(:articulo, :cable, nombre: "Cable Cobre", cantidad_en_stock: 50) }
    let!(:material) { create(:articulo, nombre: "Guantes", cantidad_en_stock: 8) }

    before do
      sign_in_as(:operador)
      visit entradas_path
      click_button "Iniciar nueva entrada"
    end

    it "hides every item field until an article is chosen" do
      expect(page).to have_select("id_articulo")
      expect(page).not_to have_field("nombre")
      expect(page).not_to have_field("nombre_punta")
      expect(page).not_to have_field("cantidad")
    end

    it "reveals the new-item fields and a cantidad for a new material" do
      select "Otro (escribir nuevo)", from: "id_articulo"

      expect(page).to have_field("nombre", disabled: false)
      expect(page).to have_field("cantidad", disabled: false)
      expect(page).not_to have_field("nombre_punta")
    end

    it "swaps cantidad for the cable fields when the new item is a cable" do
      select "Otro (escribir nuevo)", from: "id_articulo"
      check "entrada_es_cable"

      expect(page).to have_field("nombre_punta", disabled: false)
      expect(page).to have_field("longitud", disabled: false)
      expect(page).to have_field("color", disabled: false)
      expect(page).not_to have_field("cantidad")
    end

    it "reveals the cable fields for an existing cable" do
      select cable.nombre, from: "id_articulo"

      expect(page).to have_field("nombre_punta", disabled: false)
      expect(page).not_to have_field("nombre")
      expect(page).not_to have_field("cantidad")
    end

    it "reveals only cantidad for an existing material" do
      select material.nombre, from: "id_articulo"

      expect(page).to have_field("cantidad", disabled: false)
      expect(page).not_to have_field("nombre")
      expect(page).not_to have_field("nombre_punta")
    end
  end

  describe "salida form" do
    let!(:cable) { create(:articulo, :cable, nombre: "Cable Cobre", cantidad_en_stock: 50) }
    let!(:punta) { create(:stock_punta, articulo: cable, nombre_punta: "Carrete 3", longitud: 12) }
    let!(:material) { create(:articulo, nombre: "Guantes", cantidad_en_stock: 8) }

    before do
      sign_in_as(:operador)
      visit salidas_path
      click_button "Iniciar nueva salida"
    end

    it "hides the punta selector and cantidad until an article is chosen" do
      expect(page).not_to have_select("id_punta")
      expect(page).not_to have_field("cantidad")
    end

    it "reveals the punta selector for a cable" do
      select cable.nombre, from: "id_articulo"

      expect(page).to have_select("id_punta", disabled: false)
      expect(page).to have_select("id_punta", options: [ "Selecciona...", "#{punta.nombre_punta} (#{punta.longitud}m)" ])
      expect(page).not_to have_field("cantidad")
    end

    it "reveals cantidad with the stock hint for a material" do
      select material.nombre, from: "id_articulo"

      expect(page).to have_field("cantidad", disabled: false)
      expect(page).to have_content("Máximo disponible: 8")
      expect(page).not_to have_select("id_punta")
    end
  end
end
