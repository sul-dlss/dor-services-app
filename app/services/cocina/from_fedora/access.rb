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
          download: download? ? access_rights : 'none'
        }.tap do |h|
          h[:readLocation] = location if location
          h[:controlledDigitalLending] = true if cdl?
        end
      end

      private

      attr_reader :rights_metadata_ds

      def rights_object
        rights_metadata_ds.dra_object.obj_lvl
      end

      # @return [Bool] true unless the rule="no-download" has been set or if the access is citation-only or dark
      def download?
        return false if %w[citation-only dark].include? access_rights

        !rights_object.world.rule && !rights_object.group.fetch(:stanford).rule
      end

      def location
        @location ||= rights_object.location.keys.first
      end

      # Map values from dor-services
      # https://github.com/sul-dlss/dor-services/blob/b9b4768eac560ef99b4a8d03475ea31fe4ae2367/lib/dor/datastreams/rights_metadata_ds.rb#L221-L228
      # to https://github.com/sul-dlss/cocina-models/blob/main/docs/maps/DRO.json#L102
      def access_rights
        @access_rights ||=
          if world?
            'world'
          elsif stanford?
            'stanford'
          elsif dark?
            'dark'
          elsif location
            'location-based'
          else
            'citation-only'
          end
      end

      def rights_xml
        @rights_xml ||= rights_metadata_ds.ng_xml
      end

      def stanford?
        rights_xml.search('//rightsMetadata/access[@type=\'read\']/machine/group').length == 1
      end

      def world?
        rights_xml.search('//rightsMetadata/access[@type=\'read\']/machine/world').length == 1
      end

      def dark?
        rights_xml.search('//rightsMetadata/access[@type=\'discover\']/machine/none').length == 1
      end

      def cdl?
        rights_object.controlled_digital_lending
      end
    end
  end
end
