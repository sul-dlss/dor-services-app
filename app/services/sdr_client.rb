# frozen_string_literal: true

# A client for talking to sdr-services-app
class SdrClient
  # @raises [Dor::Exception] if SDR doesn't know about the object (i.e. 404 response code)
  # @raises [StandardError] if the response from SDR can't be parsed
  def self.current_version(druid)
    uri = URI("#{Settings.sdr_url}/objects/#{druid}/current_version")
    conn = Faraday.new "#{uri.scheme}://#{uri.host}"
    conn.basic_auth(uri.user, uri.password)
    response = conn.get uri.path

    if response.status == 404
      raise Dor::Exception, 'SDR is not yet answering queries about this object. ' \
      "We've seen that when an object has been transfered, SDR isn't immediately ready to answer queries"
    end

    begin
      doc = Nokogiri::XML response.body
      raise if doc.root.name != 'currentVersion'

      return Integer(doc.text)
    rescue StandardError
      raise "Unable to parse XML from SDR current_version API call.\n\turl: #{uri}\n\tstatus: #{response.status}\n\tbody: #{response.body}"
    end
  end
end
