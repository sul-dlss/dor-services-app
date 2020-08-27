# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for Collections
    class Access
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        { access: access_rights }.tap do |h|
          h[:readLocation] = location if location
          h[:download] = download? ? h[:access] : 'none'
          h[:controlled_digital_lending] = true if rights_object.controlled_digital_lending
        end
      end

      private

      attr_reader :item

      def rights_object
        item.rightsMetadata.dra_object.obj_lvl
      end

      # @return [Bool] true unless the rule="no-download" has been set or if the access is citation-only or dark
      def download?
        return false if ['controlled digital lending', 'citation-only', 'dark'].include? access_rights

        !rights_object.world.rule && !rights_object.group.fetch(:stanford).rule
      end

      def location
        @location ||= rights_object.location.keys.first
      end

      # Map values from dor-services
      # https://github.com/sul-dlss/dor-services/blob/b9b4768eac560ef99b4a8d03475ea31fe4ae2367/lib/dor/datastreams/rights_metadata_ds.rb#L221-L228
      # to https://github.com/sul-dlss/cocina-models/blob/master/docs/maps/DRO.json#L102
      def access_rights
        @access_rights ||= if rights != 'None'
                             rights.downcase
                           elsif location
                             'location-based'
                           else
                             rights.sub('None', 'citation-only').downcase
                           end
      end

      delegate :rights, to: :item
    end
  end
end
