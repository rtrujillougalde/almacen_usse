require "rails_helper"

RSpec.describe SharedProduction::DatabaseUrl do
  describe ".normalize" do
    it "rewrites a mysql:// URL to mysql2://" do
      expect(described_class.normalize("mysql://user:pass@host:3306/railway"))
        .to eq("mysql2://user:pass@host:3306/railway")
    end

    it "leaves mysql2:// URLs unchanged" do
      expect(described_class.normalize("mysql2://user:pass@host:3306/railway"))
        .to eq("mysql2://user:pass@host:3306/railway")
    end

    it "returns nil when the URL is blank" do
      expect(described_class.normalize(nil)).to be_nil
      expect(described_class.normalize("")).to be_nil
    end
  end

  describe ".sibling" do
    it "appends the suffix to the database name" do
      expect(described_class.sibling("mysql2://user:pass@host:3306/railway", "cache"))
        .to eq("mysql2://user:pass@host:3306/railway_cache")
    end

    it "normalizes mysql:// and preserves query params" do
      expect(described_class.sibling("mysql://user:pass@host:3306/railway?encoding=utf8mb4", "queue"))
        .to eq("mysql2://user:pass@host:3306/railway_queue?encoding=utf8mb4")
    end

    it "prefers an explicit override" do
      expect(
        described_class.sibling(
          "mysql2://user:pass@host:3306/railway",
          "cache",
          override: "mysql2://other:pw@db:3306/explicit_cache"
        )
      ).to eq("mysql2://other:pw@db:3306/explicit_cache")
    end

    it "returns nil when the URL is blank and there is no override" do
      expect(described_class.sibling(nil, "cache")).to be_nil
    end
  end
end
