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
      cocina_item.to_h  # call super() on this value when we are in rails 6
    end

    def deserialize(hash)
      Cocina::Models.build(hash.stringify_keys)
    end
  end
end
