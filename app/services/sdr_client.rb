# frozen_string_literal: true

# A client for talking to sdr-services-app
class SdrClient
  def self.create
    RestClient::Resource.new(Settings.sdr_url, {})
  end

  def self.current_version(druid)
    xml = create["objects/#{druid}/current_version"].get

    begin
      doc = Nokogiri::XML xml
      raise if doc.root.name != 'currentVersion'

      return Integer(doc.text)
    rescue StandardError
      raise "Unable to parse XML from SDR current_version API call: #{xml}"
    end
  end
end
