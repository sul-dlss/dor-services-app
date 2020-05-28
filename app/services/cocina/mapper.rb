# frozen_string_literal: true

module Cocina
  # Maps Dor::Items to Cocina objects
  # rubocop:disable Metrics/ClassLength
  class Mapper
    # Raised when called on something other than an item (DRO), etd, collection, or adminPolicy (APO)
    class UnsupportedObjectType < StandardError; end
    # @param [Dor::Abstract] item the Fedora object to convert to a cocina object
    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def self.build(item)
      new(item).build
    end

    # @param [Dor::Abstract] item the Fedora object to convert to a cocina object
    def initialize(item)
      @item = item
    end

    # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy]
    def build
      klass = cocina_klass
      props = if klass == Cocina::Models::DRO
                dro_props
              elsif klass == Cocina::Models::Collection
                collection_props
              elsif klass == Cocina::Models::AdminPolicy
                apo_props
              else
                raise "unable to build '#{klass}'"
              end
      klass.new(props)
    end

    # This handles Dor::Item and Dor::Etd models
    def dro_props
      {
        externalIdentifier: item.pid,
        type: dro_type,
        # Label may have been truncated, so prefer objectLabel.
        label: item.objectLabel.first || item.label,
        version: item.current_version.to_i,
        administrative: build_administrative,
        access: DROAccessBuilder.build(item),
        structural: DroStructuralBuilder.build(item)
      }.tap do |props|
        description = build_descriptive
        props[:description] = description unless description.nil?

        identification = build_identification
        identification[:catalogLinks] = [{ catalog: 'symphony', catalogRecordId: item.catkey }] if item.catkey
        props[:identification] = identification unless identification.empty?
      end
    end

    def collection_props
      {
        externalIdentifier: item.pid,
        type: Cocina::Models::Vocab.collection,
        label: item.label,
        version: item.current_version.to_i,
        administrative: build_administrative,
        access: AccessBuilder.build(item)
      }.tap do |props|
        description = build_descriptive
        props[:description] = description unless description.nil?
        identification = build_identification
        identification[:catalogLinks] = [{ catalog: 'symphony', catalogRecordId: item.catkey }] if item.catkey
        props[:identification] = identification unless identification.empty?

        description = build_descriptive
        props[:description] = description unless description.nil?
      end
    end

    def apo_props
      {
        externalIdentifier: item.pid,
        type: Cocina::Models::Vocab.admin_policy,
        label: item.label,
        version: item.current_version.to_i,
        administrative: build_apo_administrative
      }.tap do |props|
        description = build_descriptive
        props[:description] = description unless description.nil?
      end
    end

    private

    attr_reader :item

    def dro_type
      case item.contentMetadata.contentType.first
      when 'image'
        if AdministrativeTags.content_type(pid: item.pid).first =~ /^Manuscript/
          Cocina::Models::Vocab.manuscript
        else
          Cocina::Models::Vocab.image
        end
      when 'book'
        Cocina::Models::Vocab.book
      when 'media'
        Cocina::Models::Vocab.media
      when 'map'
        Cocina::Models::Vocab.map
      when 'geo'
        Cocina::Models::Vocab.geo
      when 'webarchive-seed'
        Cocina::Models::Vocab.webarchive_seed
      when '3d'
        Cocina::Models::Vocab.three_dimensional
      when 'document'
        Cocina::Models::Vocab.document
      when 'file', nil
        Cocina::Models::Vocab.object
      else
        raise "Unknown content type #{item.contentMetadata.contentType.first}"
      end
    end

    def build_identification
      case item
      when Dor::Etd
        # ETDs don't have source_id, but we can use the dissertationid (in otherId) for this purpose
        { sourceId: item.otherId.find { |id| id.start_with?('dissertationid:') } }
      when Dor::Collection
        {}
      else
        { sourceId: item.source_id }
      end
    end

    def build_descriptive
      desc = { title: [{ status: 'primary', value: TitleMapper.build(item) }] }

      # collections are registered with abstracts
      return desc if item.descMetadata.abstract.blank?

      desc[:note] = [{ type: 'summary', value: item.descMetadata.abstract.first }]
      desc
    end

    def build_apo_administrative
      {}.tap do |admin|
        registration_workflow = item.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/dissemination/workflow/@id').text
        admin[:defaultObjectRights] = item.defaultObjectRights.content
        admin[:registrationWorkflow] = registration_workflow if registration_workflow.present?
        admin[:hasAdminPolicy] = item.admin_policy_object_id if item.admin_policy_object_id
      end
    end

    def build_administrative
      {}.tap do |admin|
        admin[:hasAdminPolicy] = item.admin_policy_object_id if item.admin_policy_object_id
        release_tags = build_release_tags
        admin[:releaseTags] = release_tags unless release_tags.empty?
        projects = AdministrativeTags.project(pid: item.id)
        admin[:partOfProject] = projects.first if projects.any?
      end
    end

    def build_release_tags
      item.identityMetadata.ng_xml.xpath('//release').map do |node|
        {
          to: node.attributes['to'].value,
          what: node.attributes['what'].value,
          date: node.attributes['when'].value,
          who: node.attributes['who'].value,
          release: node.text == 'true'
        }
      end
    end

    # @todo This should have more specific type such as found in identityMetadata.objectType
    def cocina_klass
      case item
      when Dor::Item, Dor::Etd
        Cocina::Models::DRO
      when Dor::Collection
        Cocina::Models::Collection
      when Dor::AdminPolicyObject
        Cocina::Models::AdminPolicy
      else
        raise UnsupportedObjectType, "Unknown type for #{item.class}"
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
