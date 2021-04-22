# frozen_string_literal: true

module Cocina
  module FromFedora
    module Access
      # builds the access rights portion of the Access subschema
      class AccessRights
        def self.props(rights_object, rights_xml:)
          new(rights_object, rights_xml: rights_xml).props
        end

        def initialize(rights_object, rights_xml:)
          @rights_object = rights_object
          @rights_xml = rights_xml
        end

        def props
          {
            access: access_rights,
            download: download,
            readLocation: location
          }.compact.tap do |h|
            h[:controlledDigitalLending] = controlled_digital_lending? if h[:access] == 'stanford' && h[:download] == 'none'
          end
        end

        private

        attr_reader :rights_object, :rights_xml

        # @note This method implements an algorithm for determining download
        #       access for objects and files based on both the rights setting
        #       and the download setting, using helper methods that lean on the
        #       `dor-rights-auth` gem.
        def download
          # Some access types dictate no downloading. Handle those cases first.
          return 'none' if no_download? || stanford_no_download? || world_no_download? || location_no_download? || controlled_digital_lending?

          # Then check to see if download is based on location
          return 'location-based' if location_based_download?

          # If no specific download rules have been found yet and there are no explicit download rules set, set download to access rights
          return access_rights if no_world_or_group_download_rules?

          # Finally: the only remaining case is when rights are stanford + world (no-download), so grant download to stanford
          return 'stanford' if stanford_world_no_download?

          raise "Unexpected download rights: #{contextual_rights}"
        end

        # These next few methods are admittedly a little gross. But! They allow
        # objects to use the full `Dor::RightsAuth` struct, which is returned by
        # a method on the rights metadata datastream, while allowing files to
        # use the `Dor::EntityRights` substruct of `Dor::RightsAuth`, which is
        # how file rights are parsed by `dor-rights-auth`. And the algorithms
        # for determining access and download are complex, so I'm OK with the
        # timidness of these checks given the value we get in return.
        def contextual_rights
          return rights_object.obj_lvl if rights_object.respond_to?(:obj_lvl)

          rights_object
        end

        def citation_only?
          return false unless rights_object.respond_to?(:citation_only?)

          rights_object.citation_only?
        end

        def controlled_digital_lending?
          return contextual_rights.controlled_digital_lending unless contextual_rights.controlled_digital_lending.respond_to?(:value)

          contextual_rights.controlled_digital_lending.value
        end

        def dark?
          !(world? ||
            stanford? ||
            controlled_digital_lending? ||
            location)
        end

        def no_download?
          citation_only? || dark? || controlled_digital_lending?
        end

        def no_world_or_group_download_rules?
          contextual_rights.world.rule.nil? && contextual_rights.group.fetch(:stanford).rule.nil?
        end

        def stanford_no_download?
          stanford? &&
            contextual_rights.group.fetch(:stanford).rule == 'no-download' &&
            !(location && contextual_rights.location.fetch(location).value)
        end

        def world_no_download?
          world? &&
            contextual_rights.world.rule == 'no-download' &&
            !stanford? &&
            !(location && contextual_rights.location.fetch(location).value)
        end

        def location_no_download?
          location &&
            contextual_rights.location.fetch(location).value &&
            contextual_rights.location.fetch(location).rule == 'no-download'
        end

        def location_based_download?
          location &&
            contextual_rights.location.fetch(location).value &&
            contextual_rights.location.fetch(location).rule.nil?
        end

        def stanford_world_no_download?
          stanford? && contextual_rights.world.rule == 'no-download'
        end

        def stanford?
          contextual_rights.group.fetch(:stanford).value
        end

        def world?
          contextual_rights.world.value
        end

        def location
          @location ||= contextual_rights.location.keys.first
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
              raise "Cannot interpret access rights from #{rights_xml}"
            end
        end
      end
    end
  end
end
