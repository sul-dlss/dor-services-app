# frozen_string_literal: true

module Cocina
  # Serializes Cocina::Model objects for active_job
  # See https://blog.saeloun.com/2019/09/11/rails-6-custom-serializers-for-activejob-arguments.html
  class Serializer < ActiveJob::Serializers::ObjectSerializer
    def serialize?(argument)
      argument.is_a?(Cocina::Models::DRO) || argument.is_a?(Cocina::Models::DROWithMetadata)
    end

    def serialize(cocina_item)
      super(Cocina::Models.without_metadata(cocina_item).to_h)
    end

    def deserialize(hash)
      Cocina::Models.build(hash.excluding('_aj_serialized'))
    end
  end
end
