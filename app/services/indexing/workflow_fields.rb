# frozen_string_literal: true

module Indexing
  # Model for workflow fields
  class WorkflowFields
    def self.for(...)
      new(...).result
    end

    attr_reader :druid, :version, :milestones

    def initialize(druid:, version:, milestones: nil)
      @druid = druid
      @version = version
      @milestones = milestones
    end

    # @return [Hash] the partial solr document for processable concerns
    def result
      {}.tap do |solr_doc|
        add_sortable_milestones(solr_doc)
        add_status(solr_doc)
      end
    end

    private

    def status
      @status ||= Status.new(druid: druid, version: version, milestones:)
    end

    def add_status(solr_doc)
      # This is the status on the Argo show page (e.g. "v4 In accessioning (described, published, deposited)")
      solr_doc['status_ssi'] = status.display

      # This is used for Argo's "Processing Status" facet
      solr_doc['processing_status_text_ssi'] = status.display_simplified # TODO: Remove
      solr_doc['processing_status_text_ssidv'] = status.display_simplified
    end

    def sortable_milestones
      status.milestones.each_with_object({}) do |milestone, sortable|
        sortable[milestone[:milestone]] ||= []
        sortable[milestone[:milestone]] << milestone[:at].utc.xmlschema
      end
    end

    def add_sortable_milestones(solr_doc) # rubocop:disable Metrics/AbcSize
      sortable_milestones.each do |milestone, unordered_dates|
        dates = unordered_dates.sort
        # create the published_dttsi and published_day fields and the like
        dates.each do |date|
          solr_doc["#{milestone}_dttsim"] ||= []
          solr_doc["#{milestone}_dttsim"] << date unless solr_doc["#{milestone}_dttsim"].include?(date)
        end
        # fields for OAI havester to sort on: _dttsi is trie date +stored +indexed (single valued, i.e. sortable)
        # TODO: we really only need accessioned_earliest and registered_earliest
        solr_doc["#{milestone}_earliest_dttsi"] = dates.first # TODO: Remove
        solr_doc["#{milestone}_latest_dttsi"] = dates.last # TODO: Remove
        solr_doc["#{milestone}_earliest_dtpsidv"] = dates.first
        solr_doc["#{milestone}_latest_dtpsidv"] = dates.last
      end
    end

    # Determines the status of an object based on the lifecycles
    # This was extracted from the Workflow Service.
    class Status
      # verbiage we want to use to describe an item when it has completed a particular step
      STATUS_CODE_DISP_TXT = {
        0 => 'Unknown Status', # if there are no milestones for the current version, versioning process is messed.
        1 => 'Registered',
        2 => 'In accessioning',
        3 => 'In accessioning (published)',
        4 => 'In accessioning (published, deposited)',
        5 => 'Accessioned',
        6 => 'Accessioned (indexed)',
        7 => 'Accessioned (indexed, ingested)',
        8 => 'Opened'
      }.freeze

      # milestones from accessioning and the order they happen in
      STEPS = {
        'registered' => 1,
        'submitted' => 2,
        'published' => 3,
        'deposited' => 4,
        'accessioned' => 5,
        'indexed' => 6,
        'shelved' => 7,
        'opened' => 8
      }.freeze

      attr_reader :status_code, :milestones

      # @param [String] druid the object identifier
      # @param [String|Integer] version the version identifier
      # @param [Array<Hash>] milestones an array of milestone hashes
      def initialize(druid:, version:, milestones: nil)
        @druid = druid
        @version = version.to_s
        @milestones = milestones
        @status_code, @status_time = status_from_latest_current_milestone
      end

      # @param [Boolean] include_time
      # @return [String] single composed status from status_info
      def display(include_time: false)
        # use the translation table to get the appropriate verbage for the latest step
        result = "v#{version} #{STATUS_CODE_DISP_TXT[status_code]}"
        result += " #{format_date(status_time)}" if include_time
        result
      end

      def display_simplified
        simplified_status_code(STATUS_CODE_DISP_TXT[status_code])
      end

      private

      attr_reader :druid, :version, :lifecycle_routes, :status_time

      def status_from_latest_current_milestone
        # if we have an accessioned milestone, this is the last possible step and should be the status
        # regardless of timestamp
        return [STEPS['accessioned'], latest_accessioned_milestone[:at].utc.xmlschema] if currently_accessioned?

        return [0, nil] if latest_current_milestone.nil?

        [
          STEPS.fetch(latest_current_milestone.fetch(:milestone), 0),
          latest_current_milestone[:at].utc.xmlschema
        ]
      end

      # @return [String] text translation of the status code, minus any trailing parenthetical explanation
      # e.g. 'Accessioned (indexed)' and 'Accessioned (indexed, ingested)', both return 'Accessioned'
      def simplified_status_code(display)
        display.gsub(/\(.*\)$/, '').strip
      end

      def current_milestones
        milestones
          # milestone name must be in list of known steps
          .select { |m| STEPS.key?(m[:milestone]) }
          # registered milestone is only valid for v1
          .reject { |m| m[:milestone] == 'registered' && version.to_i > 1 }
          # Two possible ways the version can indicate the milestone is part of the current version:
          # if m[:version] is nil, then the milestone is active (version 0 becoming version 1)
          # if m[:version] is matches the current version, then the milestone is archived with the current version
          .select { |m| m[:version].nil? || m[:version] == version }
      end

      def latest_current_milestone
        current_milestones.max_by { |m| m[:at].utc.xmlschema }
      end

      def currently_accessioned?
        current_milestones.any? { |m| m[:milestone] == 'accessioned' }
      end

      def latest_accessioned_milestone
        current_milestones
          .select { |m| m[:milestone] == 'accessioned' }
          .max_by { |m| m[:at].utc.xmlschema }
      end

      # handles formatting UTC date/time to human readable
      # TODO: bad form to hardcode TZ here.
      def format_date(datetime)
        d =
          if datetime.is_a?(Time)
            datetime
          else
            DateTime.parse(datetime).in_time_zone(ActiveSupport::TimeZone.new('Pacific Time (US & Canada)'))
          end
        I18n.l(d).strftime('%Y-%m-%d %I:%M%p')
      rescue StandardError
        d = datetime.is_a?(Time) ? datetime : Time.zone.parse(datetime.to_s)
        d.strftime('%Y-%m-%d %I:%M%p')
      end
    end
  end
end
