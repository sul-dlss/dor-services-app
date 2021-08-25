# frozen_string_literal: true

module Cocina
  # Serializes Cocina::Model objects for active_job
  # See https://blog.saeloun.com/2019/09/11/rails-6-custom-serializers-for-activejob-arguments.html
  # class Serializer < ActiveJob::Serializers::ObjectSerializer
  class Serializer
    def serialize?(argument)
      argument.is_a?(Cocina::Models::DRO)
    end

    def serialize(cocina_item)
      # For Rails 6:
      # super(cocina_item.to_h)

      cocina_item.to_json
    end

    def deserialize(json)
      # For Rails 6:
      # Cocina::Models.build(hash.stringify_keys)
      Cocina::Models.build(JSON.parse(json))
    end
  end
end
