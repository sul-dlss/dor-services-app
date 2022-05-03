# frozen_string_literal: true

# Utility methods for generating purl links
class Purl
  def self.for(druid:)
    return nil if druid.nil?

    "#{base_url}/#{druid.delete_prefix('druid:')}"
  end

  def self.base_url
    Settings.release.purl_base_url
  end
end
