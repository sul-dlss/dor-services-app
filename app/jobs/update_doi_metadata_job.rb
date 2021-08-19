# frozen_string_literal: true

# Create the Datacite metadata and transfer it via their update API
class UpdateDoiMetadataJob < ApplicationJob
  queue_as :default

  def perform(serialized_item)
    # We can remove this next line when we upgrade to Rails 6. It will automatically be deserialized.
    cocina_item = Cocina::Serializer.new.deserialize(serialized_item)
    attributes = Cocina::ToDatacite::Attributes.mapped_from_cocina(cocina_item)
    result = client.update(id: cocina_item.identification.doi, attributes: attributes.deep_stringify_keys)
    return if result.success?

    message = "Error connecting to datacite (#{cocina_item.externalIdentifier}) " \
              "response: #{result.failure.status}: #{result.failure.body}\n" \
              "request: #{result.failure.env.request_body}"
    raise message
  end

  def client
    Datacite::Client.new(username: Settings.datacite.username,
                         password: Settings.datacite.password,
                         host: Settings.datacite.host)
  end
end
