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
      def to_solr # rubocop:disable Metrics/AbcSize
        {}.tap do |solr_doc|
          solr_doc[:id] = cocina.externalIdentifier
          solr_doc['trace_id_ss'] = trace_id
          solr_doc['current_version_ipsidv'] = cocina.version # Argo Facet field "Version"
          solr_doc['obj_label_tesim'] = cocina.label

          solr_doc['modified_latest_dtpsidv'] = modified_latest
          solr_doc['created_at_dttsi'] = created_at

          # member_of_collection_ssim is used by dor-services-app for querying for members of a
          # collection and it is a facet in Argo
          solr_doc['member_of_collection_ssim'] = collections
          solr_doc['governed_by_ssim'] = cocina.administrative.hasAdminPolicy

          # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
          solr_doc['is_member_of_collection_ssim'] = legacy_collections
          solr_doc['is_governed_by_ssim'] = "info:fedora/#{cocina.administrative.hasAdminPolicy}"

          # Used so that DSA can generate public XML whereas a constituent can find the virtual object it is part of.
          solr_doc['has_constituents_ssimdv'] = virtual_object_constituents
        end.merge(Indexing::WorkflowFields.for(druid: cocina.externalIdentifier, version: cocina.version, milestones:))
           .transform_keys(&:to_s)
      end

      def modified_latest
        cocina.modified.to_datetime.strftime('%FT%TZ')
      end

      def created_at
        cocina.created.to_datetime.strftime('%FT%TZ')
      end

      # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
      def legacy_collections
        case cocina.type
        when Cocina::Models::ObjectType.admin_policy, Cocina::Models::ObjectType.collection
          []
        else
          Array(cocina.structural&.isMemberOf).map { |col_id| "info:fedora/#{col_id}" }
        end
      end

      def collections
        return [] unless cocina.dro?

        Array(cocina.structural&.isMemberOf)
      end

      def virtual_object_constituents
        return unless cocina.dro?

        Array(cocina.structural&.hasMemberOrders).first&.members
      end
    end
  end
end
