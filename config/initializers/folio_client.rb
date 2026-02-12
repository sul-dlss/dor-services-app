# frozen_string_literal: true

# Configure folio_client singleton
begin
  FolioClient.configure(
    url: Settings.catalog.folio.okapi.url,
    login_params: {
      username: Settings.catalog.folio.okapi.username,
      password: Settings.catalog.folio.okapi.password
    },
    okapi_headers: {
      'X-Okapi-Tenant': Settings.catalog.folio.tenant_id,
      'User-Agent': "folio_client #{FolioClient::VERSION}; dor-services-app #{Rails.env}"
    }
  )
rescue StandardError => e
  # as of v0.1.0, folio_client tries to connect immediately upon configuration, which would
  # prevent running tests or rails console on laptop.  would also prevent deployment or startup
  # of dor-services-app if configuration was incorrect (missing settings, stale password, etc).
  Rails.logger.warn("Error configuring FolioClient: #{e}")
  Honeybadger.notify(e)
end
