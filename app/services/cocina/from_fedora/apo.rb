# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina APO objects from Fedora objects
    class APO
      # @param [Dor::AdminPolicyObject] fedora_apo
      # @param [Cocina::FromFedora::DataErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.props(fedora_apo, notifier: nil)
        new(fedora_apo, notifier: notifier).props
      end

      def initialize(fedora_apo, notifier: nil)
        @fedora_apo = fedora_apo
        @notifier = notifier
      end

      def props
        {
          externalIdentifier: fedora_apo.pid,
          type: Cocina::Models::Vocab.admin_policy,
          label: fedora_apo.label,
          version: fedora_apo.current_version.to_i,
          administrative: build_apo_administrative
        }.tap do |props|
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_apo.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder, mods: fedora_apo.descMetadata.ng_xml, druid: fedora_apo.pid, notifier: notifier)
          props[:description] = description unless description.nil?
        end
      end

      private

      attr_reader :fedora_apo, :notifier

      # rubocop:disable Metrics/AbcSize
      def build_apo_administrative
        {}.tap do |admin|
          registration_workflows = fedora_apo.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/registration/workflow/@id').map(&:value)
          registration_collections = fedora_apo.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/registration/collection/@id').map(&:value)
          dissemination_workflow = fedora_apo.administrativeMetadata.ng_xml.xpath('//administrativeMetadata/dissemination/workflow/@id').text
          admin[:defaultObjectRights] = fedora_apo.defaultObjectRights.content # Deprecated. Use defaultAccess instead
          admin[:defaultAccess] = APOAccess.props(fedora_apo.defaultObjectRights)
          admin[:disseminationWorkflow] = dissemination_workflow if dissemination_workflow.present?
          admin[:registrationWorkflow] = registration_workflows if registration_workflows.present?
          admin[:collectionsForRegistration] = registration_collections if registration_collections.present?
          admin[:hasAdminPolicy] = fedora_apo.admin_policy_object_id
          admin[:referencesAgreement] = fedora_apo.agreement_object_id if fedora_apo.agreement_object_id.present?
          admin[:roles] = build_roles
        end
      end
      # rubocop:enable Metrics/AbcSize

      # @return [Array<Hash>] the list of name and members
      def build_roles
        # rubocop:disable Rails/DynamicFindBy  false positive
        fedora_apo.roleMetadata.find_by_xpath('/roleMetadata/role').map do |role|
          { name: role['type'], members: workgroup_members(role) + person_members(role) + sunetid_members(role) }
        end
        # rubocop:enable Rails/DynamicFindBy
      end

      def workgroup_members(role)
        role.xpath('group/identifier[@type="workgroup"]').map do |identifier_node|
          { type: 'workgroup', identifier: identifier_node.text }
        end
      end

      def sunetid_members(role)
        role.xpath('person/identifier[@type="sunetid"]').map do |identifier_node|
          { type: 'sunetid', identifier: identifier_node.text }
        end
      end

      def person_members(role)
        role.xpath('person/identifier[@type="person"]')
            .select { |identifier_node| identifier_node.text&.start_with?('sunetid:') }
            .map do |identifier_node|
          { type: 'sunetid', identifier: identifier_node.text.delete_prefix('sunetid:') }
        end
      end
    end
  end
end
