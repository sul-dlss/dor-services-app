# frozen_string_literal: true

# This initializes the dor services client with values from settings
class DorServicesClientFactory
  def self.build
    Dor::Services::Client.configure(url: Settings.dor_services.url, token: Settings.dor_services.token, enable_get_retries: true)
  end
end
