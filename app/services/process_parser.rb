# frozen_string_literal: true

##
# Parsing Process creation request
class ProcessParser
  PROCESS_ATTRIBUTES = %i[
    process
    status
    lane_id
    lifecycle
    error_msg
    error_txt
    note
    elapsed
  ].freeze

  # These properties should be updated to nil if they are not passed.
  MUTABLE_PROPERTIES = %i[
    status
    error_msg
    error_txt
  ].freeze

  # @param [Boolean] use_default_lane_id provide "default" as lane_id if no lane_id
  def initialize(process: nil, status: nil, lane_id: nil, lifecycle: nil, error_msg: nil, # rubocop:disable Metrics/ParameterLists
                 error_txt: nil, note: nil, elapsed: 0, use_default_lane_id: true)
    @process = process
    @status = status
    @lane_id = lane_id
    @lifecycle = lifecycle
    @error_msg = error_msg
    @error_txt = error_txt
    @note = note
    @elapsed = elapsed
    @use_default_lane_id = use_default_lane_id
  end

  # Convert the args to a hash suitable for creating or updating the model.
  # This is tricky, because some properties are mutable (e.g. status and error_msg)
  # and others are not.  The lack of an error_msg means we should clear out the message
  # but the lack of a lifecycle, should not clear anything.
  def to_h
    PROCESS_ATTRIBUTES.each_with_object({}) do |attribute, hash|
      value = public_send(attribute)
      next if value.nil? && MUTABLE_PROPERTIES.exclude?(attribute)

      hash[attribute] = value
    end
  end

  attr_reader :process_element, :use_default_lane_id, :process, :status, :lifecycle, :error_msg, :error_txt, :note

  def lane_id
    return @lane_id unless @lane_id.nil?

    use_default_lane_id ? 'default' : nil
  end

  def elapsed
    @elapsed&.to_f
  end
end
