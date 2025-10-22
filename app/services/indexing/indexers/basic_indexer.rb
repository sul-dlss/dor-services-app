# frozen_string_literal: true

module Indexing
  module Indexers
    # Basic indexing for any object
    class BasicIndexer
      attr_reader :cocina, :workflow_client, :trace_id, :milestones

      def initialize(cocina:, trace_id:, milestones: nil, **)
        @cocina = cocina
        @milestones = milestones
        @trace_id = trace_id
        @workflow_client = workflow_client
      end

      # @return [Hash] the partial solr document for basic data
      def to_solr # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        {}.tap do |solr_doc|
          solr_doc[:id] = cocina.externalIdentifier
          solr_doc['trace_id_ss'] = trace_id
          solr_doc['current_version_ipsidv'] = cocina.version # Argo Facet field "Version"
          solr_doc['obj_label_tesim'] = cocina.label
          solr_doc['purl_ss'] = Purl.for(druid: cocina.externalIdentifier) if purl?
          solr_doc['modified_latest_dtpsidv'] = modified_latest
          solr_doc['created_at_dttsi'] = created_at
          solr_doc['member_of_collection_ssim'] = collections
          solr_doc['bare_member_of_collection_ssm'] = collections.map { |druid| bare_druid_for(druid) }
          solr_doc['governed_by_ssim'] = cocina.administrative.hasAdminPolicy
          solr_doc['bare_governed_by_ss'] = bare_druid_for(cocina.administrative.hasAdminPolicy)
          solr_doc['has_constituents_ssimdv'] = virtual_object_constituents
          solr_doc['constituents_count_ips'] = virtual_object_constituents.length if virtual_object_constituents
        end.merge(Indexing::WorkflowFields.for(druid: cocina.externalIdentifier, version: cocina.version, milestones:))
           .transform_keys(&:to_s)
      end

      def modified_latest
        cocina.modified.to_datetime.strftime('%FT%TZ')
      end

      def created_at
        cocina.created.to_datetime.strftime('%FT%TZ')
      end

      def collections
        return [] unless cocina.dro?

        Array(cocina.structural&.isMemberOf)
      end

      def virtual_object_constituents
        return unless cocina.dro?

        Array(cocina.structural&.hasMemberOrders).first&.members
      end

      def purl?
        !cocina.admin_policy? && cocina.access.view != 'dark'
      end

      def bare_druid_for(druid)
        druid.delete_prefix('druid:')
      end
    end
  end
end
