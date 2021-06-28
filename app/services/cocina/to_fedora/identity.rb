# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the cocina identification information to the Fedora 3 data model identityMetadata
    class Identity
      # @param [Dor::Item,Dor::Collection,Dor::Etd,Dor::AdminPolicyObject] fedora_object
      def self.initialize_identity(fedora_object)
        new(fedora_object).initialize_identity
      end

      # @param [Dor::Item,Dor::Collection,Dor::Etd,Dor::AdminPolicyObject] fedora_object
      # @param [String] label the label for the cocina object.
      def self.apply_label(fedora_object, label:)
        new(fedora_object).apply_label(label)
      end

      # @param [Dor::Item,Dor::Collection,Dor::Etd,Dor::AdminPolicyObject] fedora_object
      # @param [Array<Cocina::Model::ReleaseTag>] release_tags for collections and items.
      def self.apply_release_tags(fedora_object, release_tags:)
        new(fedora_object).apply_release_tags(release_tags)
      end

      def initialize(fedora_object)
        @fedora_object = fedora_object
      end

      def initialize_identity
        fedora_object.objectId = fedora_object.pid
        fedora_object.objectCreator = 'DOR'
        fedora_object.objectType = fedora_object.object_type # This comes from the class definition in dor-services
      end

      def apply_label(label)
        return unless fedora_object.objectLabel.empty?

        fedora_object.objectLabel = label
      end

      def apply_release_tags(release_tags)
        return if release_tags.blank?

        identity_md = fedora_object.identityMetadata
        identity_md.ng_xml_will_change!
        identity_md.ng_xml.xpath('//release').each(&:remove)
        release_tags.each do |release_tag|
          attrs = release_tag.to_h.except(:date)
          release = attrs.delete(:release)
          attrs[:when] = release_tag.date ? release_tag.date.utc.iso8601 : Time.now.utc.iso8601 # add the timestamp if necessary
          identity_md.add_value(:release, release.to_s, attrs)
        end
      end

      private

      attr_reader :fedora_object
    end
  end
end
