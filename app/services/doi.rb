# frozen_string_literal: true

# Utility methods for generating DOIs
class Doi
  def self.for(druid:)
    return nil if druid.nil?

    "#{prefix}/#{druid.delete_prefix('druid:')}"
  end

  def self.prefix
    Settings.datacite.prefix
  end
end
