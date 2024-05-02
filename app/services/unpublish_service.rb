# frozen_string_literal: true

# Unpublishes Druid from PURL
class UnpublishService
  def self.unpublish(druid:)
    raise 'You have not configured purl-fetcher (Settings.purl_fetcher.url).' unless Settings.purl_fetcher.url

    id = druid.gsub(/^druid:/, '')
    Faraday.delete("#{Settings.purl_fetcher.url}/purls/#{id}")
  end
end
