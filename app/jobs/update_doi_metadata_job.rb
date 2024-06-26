# frozen_string_literal: true

# Create the Datacite metadata and transfer it via their update API
class UpdateDoiMetadataJob < ApplicationJob
  queue_as :default

  def perform(cocina_item_json)
    cocina_item = Cocina::Models.build(JSON.parse(cocina_item_json))
    attributes = Cocina::ToDatacite::Attributes.mapped_from_cocina(cocina_item)

    Honeybadger.context(
      attributes:,
      doi: cocina_item.identification.doi,
      druid: cocina_item.externalIdentifier
    )

    result = client.update(id: cocina_item.identification.doi, attributes: attributes.deep_stringify_keys)
    return if result.success?

    raise "Error connecting to datacite (#{cocina_item.externalIdentifier}) " \
          "response: #{result.failure.status}: #{result.failure.body}\n" \
          "request: #{result.failure.env.request_body}"
  end

  def client
    Datacite::Client.new(username: Settings.datacite.username,
                         password: Settings.datacite.password,
                         host: Settings.datacite.host)
  end
end
