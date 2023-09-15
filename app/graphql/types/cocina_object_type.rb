# frozen_string_literal: true

module Types
  # Type for DROs, Collections, and AdminPolicies.
  # This defines the GraphQL data model for Cocina objects, as well as the mapping
  # from ActiveRecord cocina objects.
  class CocinaObjectType < Types::BaseObject
    # These are a superset of all of the fields for a DRO, Collection, and AdminPolicy.
    field :external_identifier, String, null: false
    field :cocina_version, String, null: false
    # Type requires a special resolver method because it is different in AR models.
    field :type, String, null: false, resolver_method: :object_type
    field :label, String, null: false
    field :version, Int, null: false
    # Note these these are nullable.
    field :access, GraphQL::Types::JSON, fallback_value: nil
    field :administrative, GraphQL::Types::JSON, fallback_value: nil
    field :description, GraphQL::Types::JSON, fallback_value: nil
    field :identification, GraphQL::Types::JSON, fallback_value: nil
    field :structural, GraphQL::Types::JSON, fallback_value: nil
    field :geographic, GraphQL::Types::JSON, fallback_value: nil

    def object_type
      object.try(:content_type) || object.try(:collection_type) || Cocina::Models::ObjectType.admin_policy
    end
  end
end
