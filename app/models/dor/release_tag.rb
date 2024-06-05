# frozen_string_literal: true

module Dor
  # Include the Dry types module
  module Types
    include Dry.Types()
  end

  # A tag that indicates the item or collection should be released.
  # This duplicates the model in dor-services-client:
  # https://github.com/sul-dlss/dor-services-client/blob/main/lib/dor/services/client/release_tag.rb
  class ReleaseTag < Dry::Struct
    transform_keys(&:to_sym)
    schema schema.strict
    # Who did this release
    # example: petucket
    attribute? :who, Types::Strict::String
    # What is being released. This item or the whole collection.
    # example: self
    attribute :what, Types::Strict::String.enum('self', 'collection')
    # When did this action happen
    attribute? :date, Types::Params::DateTime
    # What platform is it released to
    # example: Searchworks
    attribute? :to, Types::Strict::String
    attribute :release, Types::Strict::Bool.default(false)
  end
end
