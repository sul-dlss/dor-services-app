# frozen_string_literal: true

# Create the Datacite metadata and transfer it via their update API
class UpdateDoiMetadataJob < ApplicationJob
  queue_as :default

  def perform(cocina_item)
    attributes = Cocina::ToDatacite::Attributes.mapped_from_cocina(cocina_item)
    result = client.update(id: cocina_item.identification.doi, attributes: attributes.deep_stringify_keys)
    return if result.success?

    raise("Error connecting to datacite (#{cocina_item.externalIdentifier}) #{result.failure.status}: #{result.failure.body}")
  end

  def client
    Datacite::Client.new(username: Settings.datacite.username,
                         password: Settings.datacite.password,
                         host: Settings.datacite.host)
  end
end
