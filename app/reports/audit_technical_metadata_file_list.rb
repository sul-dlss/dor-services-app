# frozen_string_literal: true

# @see https://github.com/sul-dlss/technical-metadata-service/issues/510
# @see https://github.com/sul-dlss/technical-metadata-service/issues/515
# @see https://github.com/sul-dlss/technical-metadata-service/issues/517
# @see https://github.com/sul-dlss/common-accessioning/pull/1154
#
# Iterate over all closed DROs, and use the technical metadata service's
# audit endpoint to determine whether it
# * is aware of all the files it should be aware of.
# * has info on extraneous files.
# * has info for a file with the same name but different content (based on the MD5 of the file).
#
# This is intended to audit the full contents of SDR, and the techMD problem being audited was
# present for a while, so this report may produce a lot of output. It is suggested that output be
# piped through gzip to save disk space, e.g.
#
#   bin/rails r -e production 'AuditTechnicalMetadataFileList.report' | gzip > techmd_audit.`date -Iseconds`.gz
#
# Probably best to do that in a screen session since it might take a while.
#
# For a small test run, you can do something like
#   bin/rails r 'AuditTechnicalMetadataFileList.test_report'
# To follow up on one druid
#   bin/rails r 'AuditTechnicalMetadataFileList.audit_one_druid(druid: "druid:bc123df4567")'
#
# Error and info output other than an individual druid audit result (e.g. totally unexpected
# responses and exceptions, progress info) will go to a log file named for the class.
#
# @note Since we shouldn't be creating new instance of this problem, we should be able to retire
# this report once extant instances are remediated.
#
# @note If you remove this report, consider removing technical_metadata settings section and
# techMD tokens for DSA from vault if nothing else has come to need that info (and related env
# var setting from puppet).
class AuditTechnicalMetadataFileList
  FILE_INFOS_JSONPATH = '$.contains[*].structural.contains'
  FILES_FROM_RESOURCES_SQL = Arel.sql("jsonb_path_query_array(structural, '#{FILE_INFOS_JSONPATH}')")
  EXPECTED_RESPONSE_CODES = [200, 404].freeze

  def self.test_report
    report(limit: 20)
  end

  def self.report(...)
    new(...).report
  end

  def self.audit_one_druid(druid:)
    new.audit_one_druid(druid:)
  end

  def initialize(limit: nil)
    @limit = limit
  end

  attr_reader :limit

  def report
    logger.info("=== auditing technical-metadata-service for inconsistencies with current cocina file information (limit: #{limit})")

    # We iterate over all DROs to start, filtering open objects and versions other than the latest out of the batches for which
    # we actually run the queries.  We'll further filter the files we care about when processing each DRO.
    # Using in_batches means we can pluck only the info we need to use, without having to instantiate an ActiveRecord obj for
    # each Dro in each batch.
    num_processed = 0
    RepositoryObject.dros.limit(limit).in_batches.each do |batch_relation|
      batch_dro_rows = batch_relation.closed.joins(:head_version).pluck(:external_identifier, FILES_FROM_RESOURCES_SQL)
      batch_dro_rows.each do |dro_row|
        num_processed += 1
        self.class.process_dro_row(dro_row, techmd_connection, logger)
        log_progress(num_processed)
      rescue StandardError => e
        logger.warn("error auditing technical-metadata-service for Dro: #{e}")
      end
    end
  end

  def audit_one_druid(druid:)
    RepositoryObject.dros.where(external_identifier: druid).closed.joins(:head_version).pick(:external_identifier, FILES_FROM_RESOURCES_SQL).tap do |dro_row|
      self.class.process_dro_row(dro_row, techmd_connection, logger)
    end
  end

  class << self
    # @param [Array] an array of arrays.  each element in the top level list is an array containing (as the first element)
    #   a druid and (second element) a list of cocina-models file hashes grouped by resource (plucked from RepositoryObject.dros)
    def process_dro_row(dro_row, techmd_connection, logger)
      druid, preserved_file_list = preserved_dro_files(dro_row)
      if preserved_file_list.blank?
        logger.debug("skipping #{druid}: has no preserved files")
        return
      end

      logger.debug("auditing #{{ druid:, preserved_file_list: }}")
      req_params = { expected_files: preserved_file_list }.to_json
      response = techmd_connection.post("/v1/technical-metadata/audit/#{druid}", req_params, 'Content-Type' => 'application/json')
      logger.debug "#{druid}: audited technical-metadata-service; response status: #{response.status}; response body: #{response.body}"

      process_response(druid, response, logger)
    end

    private

    # @param [Array] an array containing a druid and a list of cocina-models file hashes grouped by resource
    # @return [Array] an array containing a druid and a list of cocina-models file hashes for just the
    #   preserved files, flattened (no longer grouped by resource)
    def preserved_dro_files(dro_row)
      dro_row.then do |druid, files_by_resource|
        [druid, preserved_filename_and_md5_list(files_by_resource)]
      end
    end

    # @param [Hash] a list of cocina-models file model nodes, as hashes, from cocina-models structural, grouped into subarrays by the
    #  containing resource (though with no resource info).  See FILE_INFOS_JSONPATH used in query that feeds this helper.
    # @return [Array<Hash>] a flat (no longer grouped by resource) list of filename/md5 pairs, one for each preserved file
    def preserved_filename_and_md5_list(cocina_file_list_by_resource)
      # we filter out unpreserved files, because techMD only has info on preserved files
      Array(cocina_file_list_by_resource).flatten.filter { |file| file['administrative']['sdrPreserve'] }.map do |file|
        {
          filename: file['filename'],
          md5: file['hasMessageDigests'].find { |digest| digest['type'] == 'md5' }['digest']
        }
      end
    end

    def process_response(druid, response, logger)
      unless EXPECTED_RESPONSE_CODES.include?(response.status)
        logger.warn("#{druid}: unexpected response auditing technical-metadata-service. HTTP status: #{response.status}. response body: #{response.body}")
        return
      end

      case response.status
      when 404
        puts "#{druid}: not found in technical-metadata-service database"
      when 200
        techmd_problem_info = JSON.parse(response.body).transform_values!(&:presence).compact
        return if techmd_problem_info.keys.blank?

        puts "#{druid}: found in technical-metadata-service database; inconsistencies with latest cocina: #{techmd_problem_info}"
      end
    end
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log', "#{self.class.name}.log"))
  end

  def retry_options
    {
      max: 3,
      # The default retriable/idempotent HTTP methods, plus POST. As of May 2024, POST is the only
      # HTTP method this class actually uses (for a read-only operation, but the file list parameter
      # might exceed the traditional max for total URL query param size, hence POST instead of GET).
      methods: %i[delete get head options put post]
    }
  end

  def techmd_connection
    @techmd_connection ||= Faraday.new(Settings.technical_metadata.url) do |builder|
      builder.request :retry, retry_options
      builder.use Faraday::Request::UrlEncoded
      builder.adapter Faraday.default_adapter
      builder.headers[:user_agent] = "dor-services-app #{Socket.gethostname}"
      builder.headers['Authorization'] = "Bearer #{Settings.technical_metadata.token}"
    end
  end

  def num_dros
    @num_dros ||= RepositoryObject.dros.count
  end

  def progress_notification_chunk_size
    @progress_notification_chunk_size ||= num_dros / 10
  end

  def log_progress(num_processed)
    return unless (num_processed % progress_notification_chunk_size).zero?

    logger.info("audited #{num_processed} of #{num_dros} DROs (#{num_processed.to_f / num_dros} percent complete)")
  end
end
