require "rails_helper"
require "rake"

RSpec.describe "stock:drift" do
  before(:all) do
    Rake.application = Rake::Application.new
    Rake::Task.define_task(:environment)
    Rake.application.rake_require("tasks/stock", [ Rails.root.join("lib").to_s ])
  end

  let(:task) { Rake::Task["stock:drift"] }

  after { task.reenable }

  it "reports nothing when the cables agree with their puntas" do
    cable = create(:articulo, :cable, cantidad_en_stock: 12)
    create(:stock_punta, articulo: cable, longitud: 12)

    expect { task.invoke }.to output(/Sin diferencias/).to_stdout
  end

  it "names the cable and the size of the gap" do
    cable = create(:articulo, :cable, nombre: "Cable Cobre", cantidad_en_stock: 5)
    create(:stock_punta, articulo: cable, longitud: 12)

    expect { task.invoke }.to output(/Cable Cobre.*\+7\.00/m).to_stdout
  end

  it "leaves the drifted rows alone, since fixing them is a separate decision" do
    cable = create(:articulo, :cable, cantidad_en_stock: 5)
    create(:stock_punta, articulo: cable, longitud: 12)

    expect { task.invoke }.to output.to_stdout
    expect(cable.reload.cantidad_en_stock).to eq(5)
  end
end
