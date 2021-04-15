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
          download: download,
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

      delegate :controlled_digital_lending?, :dark?, :citation_only?, :obj_lvl, to: :rights_object

      def rights_object
        rights_metadata_ds.dra_object
      end

      def copyright
        rights_metadata_ds.copyright.first.presence
      end

      def use_statement
        rights_metadata_ds.use_statement.first.presence
      end

      # @note This method implements an algorithm for determining download
      #       access based on both the object-level rights and the object-level
      #       download, using helper methods that lean on the `dor-rights-auth`
      #       gem.
      def download
        # Some access types dictate no downloading. Handle those cases first.
        return 'none' if no_download? || stanford_no_download? || world_no_download? || location_no_download?

        # Then check to see if download is based on location
        return 'location-based' if location_based_download?

        # If no specific download rules have been found yet and there are no explicit download rules set, set download to access rights
        return access_rights if no_world_or_group_download_rules?

        # Finally: the only remaining case is when rights are stanford + world (no-download), so grant download to stanford
        return 'stanford' if stanford_world_no_download?

        raise "Unexpected download rights: #{obj_lvl}"
      end

      def no_download?
        citation_only? || dark? || controlled_digital_lending?
      end

      def no_world_or_group_download_rules?
        obj_lvl.world.rule.nil? && obj_lvl.group.fetch(:stanford).rule.nil?
      end

      def stanford_no_download?
        stanford? &&
          obj_lvl.group.fetch(:stanford).rule == 'no-download' &&
          !(location && obj_lvl.location.fetch(location).value)
      end

      def world_no_download?
        world? &&
          obj_lvl.world.rule == 'no-download' &&
          !stanford? &&
          !(location && obj_lvl.location.fetch(location).value)
      end

      def location_no_download?
        location &&
          obj_lvl.location.fetch(location).value &&
          obj_lvl.location.fetch(location).rule == 'no-download'
      end

      def location_based_download?
        location &&
          obj_lvl.location.fetch(location).value &&
          obj_lvl.location.fetch(location).rule.nil?
      end

      def stanford_world_no_download?
        stanford? && obj_lvl.world.rule == 'no-download'
      end

      def stanford?
        obj_lvl.group.fetch(:stanford).value
      end

      def world?
        obj_lvl.world.value
      end

      def location
        @location ||= obj_lvl.location.keys.first
      end

      # Map values from dor-services
      # https://github.com/sul-dlss/dor-services/blob/b9b4768eac560ef99b4a8d03475ea31fe4ae2367/lib/dor/datastreams/rights_metadata_ds.rb#L221-L228
      # to https://github.com/sul-dlss/cocina-models/blob/main/docs/maps/DRO.json#L102
      def access_rights
        @access_rights ||=
          if world?
            'world'
          elsif stanford? || controlled_digital_lending?
            'stanford'
          elsif citation_only?
            'citation-only'
          elsif dark?
            'dark'
          elsif location
            'location-based'
          else
            raise "Cannot interpret access rights from #{rights_metadata_ds.to_xml}"
          end
      end
    end
  end
end
