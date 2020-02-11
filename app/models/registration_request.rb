# frozen_string_literal: true

require 'uuidtools'

# This represents the request a user could make to register an object
class RegistrationRequest
  # @param [Hash{Symbol => various}] params
  # @option params [String] :object_type required
  # @option params [String] :label required
  # @option params [String] :admin_policy required
  # @option params [String] :metadata_source
  # @option params [String] :rights
  # @option params [String] :collection
  # @option params [String] :abstract
  # @option params [Hash{String => String}] :source_id Primary ID from another system, max one key/value pair!
  # @option params [Hash] :other_ids including :uuid if known
  # @option params [String] :pid Fully qualified PID if you don't want one generated for you
  # @option params [Array<String>] :seed_datastream datastream_names (only 'descMetadata' is a permitted value)
  # @option params [Array] :tags
  def initialize(params)
    @params = params
  end

  # Raises Dor::ParameterError if the parameters aren't valid
  def validate!
    %i[object_type label admin_policy].each do |required_param|
      raise Dor::ParameterError, "#{required_param.inspect} must be specified in call to register_object" unless params[required_param]
    end
    raise Dor::ParameterError, 'label cannot be empty to call register_object' if params[:label].empty? && metadata_source == 'label'

    raise Dor::ParameterError, "Unknown item type: '#{object_type}'" if item_class.nil?

    raise Dor::ParameterError, "Unknown value for seed_datastream: '#{params[:seed_datastream]}'" if params[:seed_datastream] && params[:seed_datastream] != ['descMetadata']

    raise ArgumentError, ":source_id Hash can contain at most 1 pair: recieved #{source_id.size}" if source_id.size > 1

    raise Dor::ParameterError, "Unknown rights setting '#{rights}' when calling #{name}.register_object" if rights && rights != 'default' && !Dor::RightsMetadataDS.valid_rights_type?(rights)
  end

  def pid
    params[:pid]
  end

  # TODO: Move to validate
  def rights
    params[:rights]
  end

  def object_type
    params[:object_type]
  end

  def admin_policy
    params[:admin_policy]
  end

  def item_class
    Dor.registered_classes[object_type]
  end

  def metadata_source
    params[:metadata_source]
  end

  def seed_desc_metadata
    params[:seed_datastream] && params[:seed_datastream] == ['descMetadata']
  end

  def label
    params[:label].length > 254 ? params[:label][0, 254] : params[:label]
  end

  def abstract
    params[:abstract]
  end

  def source_id
    params[:source_id] || {}
  end

  def other_ids
    hash = params[:other_ids] || {}
    hash[:uuid] ||= UUIDTools::UUID.timestamp_create.to_s
    hash
  end

  def tags
    params[:tags] || []
  end

  def collection
    params[:collection]
  end

  private

  attr_reader :params
end
