# frozen_string_literal: true

# Utility methods for generating purl links
class Purl
  def self.for(druid:)
    return nil if druid.nil?

    "#{base_url}/#{druid.delete_prefix('druid:')}"
  end

  def self.purl?(node)
    node.start_with?("https://#{host}") || node.start_with?("http://#{host}")
  end

  # the purl without the protocol part
  def self.host
    @host ||= base_url.sub(%r{^https?://}, '')
  end

  def self.base_url
    Settings.release.purl_base_url
  end
end
