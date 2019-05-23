# frozen_string_literal: true

module Cocina
  # A digital repository object.  See https://github.com/sul-dlss-labs/taco/blob/master/maps/DRO.json
  class DRO < Dry::Struct
    attribute :externalIdentifier, Types::Strict::String
    attribute :type, Types::Strict::String
    attribute :label, Types::Strict::String

    def as_json(*)
      {
        externalIdentifier: externalIdentifier,
        type: type,
        label: label
      }
    end
  end
end
