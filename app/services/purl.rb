# frozen_string_literal: true

# Utility methods for generating purl links
class Purl
  def self.for(druid:)
    return nil if druid.nil?

    "#{Settings.release.purl_base_url}/#{druid.delete_prefix('druid:')}"
  end
end
