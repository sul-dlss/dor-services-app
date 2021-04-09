# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for Collections
    class Access
      def self.collection_props(rights_metadata_ds)
        props = new(rights_metadata_ds).props
        # Collection access does not have download
        props.delete(:download)
        props
      end

      def initialize(rights_metadata_ds)
        @rights_metadata_ds = rights_metadata_ds
      end

      def props
        {
          access: access_rights,
          download: download? ? access_rights : 'none',
          readLocation: location,
          license: License.find(rights_metadata_ds),
          copyright: copyright,
          useAndReproductionStatement: use_statement
        }.compact.tap do |h|
          h[:controlledDigitalLending] = true if controlled_digital_lending?
        end
      end

      private

      attr_reader :rights_metadata_ds

      delegate :controlled_digital_lending?, :dark?, to: :rights_object

      def rights_object
        rights_metadata_ds.dra_object
      end

      def copyright
        rights_metadata_ds.copyright.first.presence
      end

      def use_statement
        rights_metadata_ds.use_statement.first.presence
      end

      # @return [Bool] true unless the rule="no-download" has been set or if the access is citation-only or dark
      def download?
        return false if %w[citation-only dark].include?(access_rights)

        !rights_object.obj_lvl.world.rule && !rights_object.obj_lvl.group.fetch(:stanford).rule
      end

      def location
        @location ||= rights_object.obj_lvl.location.keys.first
      end

      # Map values from dor-services
      # https://github.com/sul-dlss/dor-services/blob/b9b4768eac560ef99b4a8d03475ea31fe4ae2367/lib/dor/datastreams/rights_metadata_ds.rb#L221-L228
      # to https://github.com/sul-dlss/cocina-models/blob/main/docs/maps/DRO.json#L102
      def access_rights
        @access_rights ||=
          if rights_object.obj_lvl.world.value
            'world'
          elsif rights_object.obj_lvl.group.fetch(:stanford).value
            'stanford'
          elsif dark?
            'dark'
          elsif location
            'location-based'
          else
            'citation-only'
          end
      end
    end
  end
end
