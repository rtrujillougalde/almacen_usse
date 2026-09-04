require "rails_helper"

RSpec.describe SharedProduction::Prepare do
  describe ".call" do
    it "skips when DATABASE_URL is missing" do
      result = described_class.call(database_url: nil)

      expect(result.skipped?).to eq(true)
      expect(result.reason).to eq("DATABASE_URL is missing")
    end

    it "does not recreate inventory tables or drop users" do
      articulo = create(:articulo, nombre: "Existing Stock")
      users_before = User.count

      result = described_class.call(database_url: "mysql2://127.0.0.1/almacen_usse_rails_test")

      expect(result.skipped?).to eq(false)
      expect(Articulo.find(articulo.id_articulo).nombre).to eq("Existing Stock")
      expect(User.count).to eq(users_before)
      expect(ActiveRecord::Base.connection.data_source_exists?("users")).to eq(true)
    end

    it "records domain migration versions so create_table is not re-run" do
      described_class.call(database_url: "mysql2://127.0.0.1/almacen_usse_rails_test")

      versions = ActiveRecord::Base.connection_pool.schema_migration.versions
      described_class::DOMAIN_MIGRATION_VERSIONS.each do |version|
        expect(versions).to include(version)
      end
    end

    it "never prepares all databases or loads schema.rb on the primary" do
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema)
      allow(ActiveRecord::Tasks::DatabaseTasks).to receive(:prepare_all)

      described_class.call(database_url: "mysql2://127.0.0.1/almacen_usse_rails_test")

      expect(ActiveRecord::Tasks::DatabaseTasks).not_to have_received(:prepare_all)
      expect(ActiveRecord::Tasks::DatabaseTasks).not_to have_received(:load_schema)
    end
  end
end
