# frozen_string_literal: true

# Unpublishes Druid from PURL
class UnpublishService
  def unpublish(druid:)
    raise 'You have not configured purl-fetcher (Settings.purl_services_url).' unless Settings.purl_services_url

    id = druid.gsub(/^druid:/, '')
    Faraday.delete("#{Settings.purl_services_url}/purls/#{id}")
  end
end
