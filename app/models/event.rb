# frozen_string_literal: true

# An event in the history of an SDR object.
class Event < ApplicationRecord
  EVENT_TYPES = [
    # Created by DSA
    'accession_request',
    'accession_request_aborted',
    'cleanup-workspace',
    'collection_changed',
    'delete',
    'embargo_released',
    'publish_request_received',
    'publishing_complete',
    'registration',
    'shelving_complete',
    'update',
    'user_version_created',
    'user_version_moved',
    'user_version_permanently_withdrawn',
    'user_version_withdrawn',
    'version_close',
    'version_discard',
    'version_open',
    # Deprecated: formerly created by DSA
    'cleanup_request_received',
    'legacy-registration',
    'legacy_metadata_update',
    'preserve_request_received',
    'shelve_request_received',
    'unpublish_complete',
    'unpublish_request_received',
    'update_complete',
    # Created by Argo
    'argo_permission_created',
    'argo_permission_deleted',
    # Created by H3
    'h3_collection_settings_updated',
    'h3_globus_staged',
    'h3_owner_changed',
    'h3_review_approved',
    'h3_review_requested',
    'h3_review_returned',
    # Created by Preservation Catalog
    'druid_version_replicated',
    'preservation_audit_failure',
    'preservation_audit_success',
    # Created by the SearchWorks indexer (indexing_skipped and indexing_errored are also created by Dataworks)
    'indexing_deleted',
    'indexing_errored',
    'indexing_skipped',
    'indexing_success',
    # Created by EarthWorks
    'earthworks_indexing_deleted',
    'earthworks_indexing_errored',
    'earthworks_indexing_skipped',
    'earthworks_indexing_success',
    # Created by Dataworks
    'indexing_deletion_scheduled',
    'indexing_scheduled',
    # Created by common-accessioning (OCR and speech-to-text)
    'ocr_errored',
    'ocr_success',
    'stt-create-error',
    'stt-create-success'
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
