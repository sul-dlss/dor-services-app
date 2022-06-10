# frozen_string_literal: true

# Applies the AdminPolicy defaults to a repository object
class ApplyAdminPolicyDefaults
  class UnsupportedObjectTypeError < StandardError; end
  class UnsupportedWorkflowStateError < StandardError; end

  ALLOWED_WORKFLOW_STATES = %w[Registered Opened].freeze
  COLLECTION_ACCESS = {
    'citation-only' => 'world',
    'dark' => 'dark',
    'location-based' => 'world',
    'stanford' => 'world',
    'world' => 'world'
  }.freeze
  COLLECTION_ACCESS_PROPS = %i[view copyright license useAndReproductionStatement].freeze
  FILE_ACCESS = {
    'citation-only' => 'dark',
    'dark' => 'dark',
    'location-based' => 'location-based',
    'stanford' => 'stanford',
    'world' => 'world'
  }.freeze
  FILE_ACCESS_PROPS = %i[view controlledDigitalLending download location].freeze

  def self.apply(cocina_object:)
    new(cocina_object:).apply
  end

  attr_reader :cocina_object

  def initialize(cocina_object:)
    @cocina_object = cocina_object

    validate_object_type!
    validate_workflow_state!
  end

  def apply
    UpdateObjectService.update(updated_cocina_object)
  end

  private

  def validate_object_type!
    return if @cocina_object.dro? || @cocina_object.collection?

    raise UnsupportedObjectTypeError, "#{@cocina_object.externalIdentifier} is a #{@cocina_object.class} and this type cannot have APO defaults applied"
  end

  def validate_workflow_state!
    return if current_workflow_state.in?(ALLOWED_WORKFLOW_STATES)

    raise UnsupportedWorkflowStateError, <<~ERROR_MESSAGE.chomp
      #{@cocina_object.externalIdentifier} is in a state in which it cannot be modified \
      (#{current_workflow_state}): APO defaults can only be applied when an object is either \
      registered or opened for versioning
    ERROR_MESSAGE
  end

  def current_workflow_state
    WorkflowClientFactory
      .build
      .status(druid: @cocina_object.externalIdentifier, version: @cocina_object.version)
      .display_simplified
  end

  def updated_cocina_object
    access_updated = @cocina_object.new(
      # Note that this is a replace, not a merge.
      access: access_properties_for(type: cocina_type)
    )
    return access_updated unless access_updated.dro? && access_updated.structural&.contains&.any?

    access_updated.new(
      structural: @cocina_object.structural.new(
        contains: @cocina_object.structural.contains.map do |file_set|
          file_set.new(
            structural: file_set.structural.new(
              contains: file_set.structural.contains.map do |file|
                file.new(file_properties(file:))
              end
            )
          )
        end
      )
    )
  end

  def file_properties(file:)
    updated_file_access = access_properties_for(type: :file)

    { access: updated_file_access }.tap do |props|
      next if updated_file_access[:view] != 'dark'

      props[:administrative] = file.administrative.new(shelve: false)
    end
  end

  def cocina_type
    if cocina_object.dro?
      :dro
    elsif cocina_object.collection?
      :collection
    end
  end

  def access_properties_for(type:)
    case type
    when :file
      default_access_from_apo.slice(*FILE_ACCESS_PROPS).tap { |access| access[:view] = FILE_ACCESS[access[:view]] }
    when :collection
      default_access_from_apo.slice(*COLLECTION_ACCESS_PROPS).tap { |access| access[:view] = COLLECTION_ACCESS[access[:view]] }
    when :dro
      default_access_from_apo
    end
  end

  def default_access_from_apo
    @default_access_from_apo ||= CocinaObjectStore
                                 .find(@cocina_object.administrative.hasAdminPolicy)
                                 .administrative
                                 .accessTemplate
                                 .to_h
                                 .with_indifferent_access
  end
end
