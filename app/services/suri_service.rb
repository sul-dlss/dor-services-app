# frozen_string_literal: true

# Use the SURI service to mint an identifier
class SuriService
  class MalformedDruidError < RuntimeError; end

  def self.mint_id
    # POST with no body
    response = Faraday.post("#{Settings.suri.url}/identifiers")
    druid = "druid:#{response.body}"
    return druid if DruidTools::Druid.valid?(druid, true)

    raise MalformedDruidError, "SURI service returned a malformed druid: #{druid}"
  end
end
