# frozen_string_literal: true

require "uri"

module SharedProduction
  class DatabaseUrl
    def self.normalize(url)
      return if url.blank?

      url.sub(/\Amysql:/, "mysql2:")
    end

    def self.database_name(url)
      normalized = normalize(url)
      return if normalized.blank?

      URI.parse(normalized).path.to_s.delete_prefix("/").presence
    end

    def self.with_database(url, fallback = nil)
      normalized = normalize(url)
      return if normalized.blank?
      return normalized if database_name(normalized).present?
      return if fallback.blank?

      uri = URI.parse(normalized)
      uri.path = "/#{fallback}"
      uri.to_s
    end

    def self.sibling(url, suffix, override: nil)
      return override if override.present?

      named = with_database(url)
      return if named.blank?

      uri = URI.parse(named)
      db = uri.path.to_s.delete_prefix("/")
      uri.path = "/#{db}_#{suffix}"
      uri.to_s
    end
  end
end
