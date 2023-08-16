# frozen_string_literal: true

# This was generated by graphql gem and then modified.
module Types
  # Query type for dor services schema.
  class QueryType < Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    # Get a specific DRO, Collection, or AdminPolicy by its external identifier
    field :cocina_object, Types::CocinaObjectType, null: false, extras: [:lookahead] do
      argument :external_identifier, String, required: true
    end
    def cocina_object(external_identifier:, lookahead:)
      # Lookahead allows access to the actual fields that were requested.
      selected_fields = lookahead.selections.map(&:name)
      # The type of cocina object isn't known, so attempt to retrieve all types.
      cocina_object = find_cocina_object(clazz: Dro, selected_fields:, allowed_fields: DRO_ALLOWED_FIELDS, external_identifier:) ||
                      find_cocina_object(clazz: Collection, selected_fields:, allowed_fields: COLLECTION_ALLOWED_FIELDS, external_identifier:) ||
                      find_cocina_object(clazz: AdminPolicy, selected_fields:, allowed_fields: BASE_ALLOWED_FIELDS, external_identifier:)

      raise GraphQL::ExecutionError, 'Cocina object not found' if cocina_object.nil?

      cocina_object
    end

    private

    BASE_ALLOWED_FIELDS = %i[external_identifier cocina_version label version administrative description].freeze
    DRO_ALLOWED_FIELDS = BASE_ALLOWED_FIELDS + %i[content_type access identification structural geographic]
    COLLECTION_ALLOWED_FIELDS = BASE_ALLOWED_FIELDS + %i[collection_type access identification]

    def find_cocina_object(selected_fields:, allowed_fields:, external_identifier:, clazz:)
      # Use an AR select to only retrieve the fields that were requested.
      # Otherwise, all fields would be retrieved from the DB, even if they weren't requested.
      # To avoid bad queries, non-allowed fields are removed.
      # The allowed fields vary based on the type of cocina object.
      allowed_selected_fields = (selected_fields + %i[content_type collection_type]) & allowed_fields
      clazz.select(*allowed_selected_fields).find_by(external_identifier:)
    end
  end
end