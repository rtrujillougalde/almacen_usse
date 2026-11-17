require "rails_helper"

RSpec.describe Trabajador do
  def create_grupo(nombre = "A")
    Grupo.create!(nombre: nombre)
  end

  it "assigns id_usse starting at 400" do
    grupo = create_grupo
    first = Trabajador.create!(nombre: "Ana", grupo: grupo)
    second = Trabajador.create!(nombre: "Luis", grupo: grupo)

    expect(first.id_usse).to eq(400)
    expect(second.id_usse).to eq(401)
  end

  it "requires a group" do
    trabajador = Trabajador.new(nombre: "Ana")

    expect(trabajador).not_to be_valid
    expect(trabajador.errors[:grupo]).to be_present
  end

  it "allows a blank antidoping result and a known blood type" do
    trabajador = Trabajador.create!(nombre: "Ana", grupo: create_grupo, tipo_sangre: "O+")

    expect(trabajador.antidoping).to be_nil
    expect(trabajador).to be_o_positivo
  end

  it "keeps one documentos row per worker" do
    trabajador = Trabajador.create!(nombre: "Ana", grupo: create_grupo)
    Documento.create!(trabajador: trabajador)

    duplicate = Documento.new(trabajador: trabajador)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:id_trabajador]).to be_present
  end
end
