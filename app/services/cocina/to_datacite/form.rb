# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description form attributes to the DataCite types attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Form
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite types attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.type_attributes(cocina_desc)
        new(cocina_desc).type_attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of DataCite types attributes, conforming to the expectations of HTTP PUT request to DataCite
      def type_attributes
        return {} if cocina_desc&.form.blank?

        {}.tap do |attribs|
          attribs[:resourceTypeGeneral] = resource_type_general if resource_type_general
          attribs[:resourceType] = resource_type if resource_type
        end
      end

      private

      attr :cocina_desc

      # @return String DataCite resourceTypeGeneral value
      def resource_type_general
        @resource_type_general ||= cocina_desc.form&.find { |cocina_form| datacite_resource_types_form?(cocina_form) }&.value
      end

      # @return [String] DataCite resourceType value
      def resource_type
        @resource_type ||= begin
          self_deposit_form = cocina_desc.form&.find { |cocina_form| self_deposit_form?(cocina_form) }

          subtypes = self_deposit_subtypes(self_deposit_form)
          if subtypes.blank?
            self_deposit_type(self_deposit_form)
          else
            subtypes.filter_map { |subtype| subtype if subtype != resource_type_general }.compact.join('; ')
          end
        end
      end

      # call with cocina form element for Stanford self deposit resource types
      # @return String the value from the structuredValue when the type is 'type' for the cocina form element
      def self_deposit_type(cocina_self_deposit_form)
        cocina_self_deposit_form&.structuredValue&.each do |struct_val|
          return struct_val.value if struct_val.type == 'type'
        end
      end

      def self_deposit_subtypes(cocina_self_deposit_form)
        cocina_self_deposit_form&.structuredValue&.map do |struct_val|
          struct_val.value if struct_val.type == 'subtype'
        end&.compact
      end

      def self_deposit_form?(cocina_form)
        cocina_form.type == 'resource type' &&
          cocina_form.source&.value == 'Stanford self-deposit resource types'
      end

      def datacite_resource_types_form?(cocina_form)
        cocina_form.source&.value == 'DataCite resource types'
      end
    end
  end
end
