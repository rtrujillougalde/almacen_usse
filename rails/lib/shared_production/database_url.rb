# frozen_string_literal: true

require "uri"

module SharedProduction
  class DatabaseUrl
    def self.normalize(url)
      return if url.blank?

      url.sub(/\Amysql:/, "mysql2:")
    end

    def self.sibling(url, suffix, override: nil)
      return override if override.present?

      normalized = normalize(url)
      return if normalized.blank?

      uri = URI.parse(normalized)
      db = uri.path.to_s.delete_prefix("/")
      return normalized if db.blank?

      uri.path = "/#{db}_#{suffix}"
      uri.to_s
    end
  end
end
