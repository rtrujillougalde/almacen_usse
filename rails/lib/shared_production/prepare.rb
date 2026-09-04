# frozen_string_literal: true

module SharedProduction
  class Prepare
    DOMAIN_MIGRATION_VERSIONS = %w[20260904190837 20260904191937].freeze
    USERS_MIGRATION_VERSION = "20260904190837"
    DOMAIN_TABLES_MIGRATION_VERSION = "20260904191937"
    DOMAIN_TABLES = %w[
      proveedores proyectos articulos movimientos stock_puntas detalle_movimientos
    ].freeze
    SOLID_ROLES = %w[cache queue cable].freeze
    USERS_MIGRATION_FILE = "20260904190837_devise_create_users.rb"

    Result = Data.define(:skipped?, :reason)

    def self.call(database_url: ENV["DATABASE_URL"])
      new(database_url:).call
    end

    def initialize(database_url:)
      @database_url = database_url
    end

    def call
      if @database_url.blank?
        return Result.new(skipped?: true, reason: "DATABASE_URL is missing")
      end

      ensure_users_table!
      record_existing_domain_migrations!
      prepare_solid_databases!
      migrate_primary!

      Result.new(skipped?: false, reason: nil)
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def schema_migration
      ActiveRecord::Base.connection_pool.schema_migration
    end

    def ensure_users_table!
      return if connection.data_source_exists?("users")

      load Rails.root.join("db/migrate", USERS_MIGRATION_FILE)
      DeviseCreateUsers.new.change
    end

    def record_existing_domain_migrations!
      schema_migration.create_table

      DOMAIN_MIGRATION_VERSIONS.each do |version|
        next if schema_migration.versions.include?(version)
        next if version == USERS_MIGRATION_VERSION && !connection.data_source_exists?("users")
        next if version == DOMAIN_TABLES_MIGRATION_VERSION && !domain_tables_exist?

        schema_migration.create_version(version)
      end
    end

    def domain_tables_exist?
      DOMAIN_TABLES.all? { |table| connection.data_source_exists?(table) }
    end

    def prepare_solid_databases!
      SOLID_ROLES.each do |name|
        config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: name)
        next if config.nil?

        create_and_load_solid(config)
      end
    end

    def create_and_load_solid(config)
      begin
        ActiveRecord::Tasks::DatabaseTasks.create(config)
      rescue ActiveRecord::DatabaseAlreadyExists
        # Sibling Solid database already exists on this MySQL server.
      end

      return if solid_schema_loaded?(config)

      ActiveRecord::Tasks::DatabaseTasks.load_schema(config)
    end

    def solid_schema_loaded?(config)
      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(config) do |conn|
        marker =
          case config.name
          when "cache" then "solid_cache_entries"
          when "queue" then "solid_queue_jobs"
          when "cable" then "solid_cable_messages"
          end

        marker && conn.data_source_exists?(marker)
      end
    end

    def migrate_primary!
      ActiveRecord::Base.connection_pool.migration_context.migrate
    end
  end
end
