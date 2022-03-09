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
          type: Cocina::Models::ObjectType.admin_policy,
          label: cocina_label,
          version: fedora_apo.current_version.to_i,
          administrative: build_apo_administrative
        }.tap do |props|
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_apo.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder, mods: fedora_apo.descMetadata.ng_xml, druid: fedora_apo.pid, label: cocina_label, notifier: notifier)
          props[:description] = description unless description.nil?
        end
      end

      private

      attr_reader :fedora_apo, :notifier

      def cocina_label
        @cocina_label ||= Label.for(fedora_apo)
      end

      def build_apo_administrative
        {
          disseminationWorkflow: dissemination_workflow,
          registrationWorkflow: registration_workflows,
          collectionsForRegistration: registration_collections,
          accessTemplate: APOAccess.props(fedora_apo.defaultObjectRights),
          hasAdminPolicy: fedora_apo.admin_policy_object_id,
          hasAgreement: fedora_apo.agreement_object_id,
          roles: build_roles
        }.compact
      end

      def registration_workflows
        administrative_ng.xpath('//administrativeMetadata/registration/workflow/@id').map(&:value).presence
      end

      def registration_collections
        administrative_ng.xpath('//administrativeMetadata/registration/collection/@id').map(&:value).presence
      end

      def dissemination_workflow
        administrative_ng.xpath('//administrativeMetadata/dissemination/workflow/@id').text.presence
      end

      def administrative_ng
        fedora_apo.administrativeMetadata.ng_xml
      end

      # @return [Array<Hash>] the list of name and members
      def build_roles
        # rubocop:disable Rails/DynamicFindBy  false positive
        fedora_apo.roleMetadata.find_by_xpath('/roleMetadata/role').filter_map do |role|
          members = workgroup_members(role) + person_members(role) + sunetid_members(role)

          members.present? ? { name: role['type'], members: members } : nil
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
