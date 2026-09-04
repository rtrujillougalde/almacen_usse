require "rails_helper"
require "yaml"
require "erb"

RSpec.describe "config/database.yml" do
  def load_database_yml
    yaml = ERB.new(Rails.root.join("config/database.yml").read, trim_mode: "-").result
    YAML.safe_load(yaml, aliases: true)
  end

  it "derives cache, queue, and cable URLs from DATABASE_URL" do
    original_url = ENV["DATABASE_URL"]
    original_cache = ENV["CACHE_DATABASE_URL"]
    ENV["DATABASE_URL"] = "mysql://user:pass@host:3306/inventory"
    ENV.delete("CACHE_DATABASE_URL")

    config = load_database_yml.fetch("production")

    expect(config.dig("cache", "url")).to eq("mysql2://user:pass@host:3306/inventory_cache")
    expect(config.dig("queue", "url")).to eq("mysql2://user:pass@host:3306/inventory_queue")
    expect(config.dig("cable", "url")).to eq("mysql2://user:pass@host:3306/inventory_cable")
  ensure
    restore_env("DATABASE_URL", original_url)
    restore_env("CACHE_DATABASE_URL", original_cache)
  end

  it "prefers CACHE_DATABASE_URL when set" do
    original_url = ENV["DATABASE_URL"]
    original_cache = ENV["CACHE_DATABASE_URL"]
    ENV["DATABASE_URL"] = "mysql2://user:pass@host:3306/inventory"
    ENV["CACHE_DATABASE_URL"] = "mysql2://other:pw@db:3306/explicit_cache"

    config = load_database_yml.fetch("production")

    expect(config.dig("cache", "url")).to eq("mysql2://other:pw@db:3306/explicit_cache")
  ensure
    restore_env("DATABASE_URL", original_url)
    restore_env("CACHE_DATABASE_URL", original_cache)
  end

  def restore_env(key, value)
    if value.nil?
      ENV.delete(key)
    else
      ENV[key] = value
    end
  end
end
