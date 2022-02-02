# frozen_string_literal: true

# TODO: This controller is doing way too much now. Consider extracting most of what is below into a new service object.
# Applies the AdminPolicy defaults to a repository object
class AdminPolicyDefaultsController < ApplicationController
  ALLOWED_WORKFLOW_STATES = %w[Registered Opened].freeze
  COLLECTION_ACCESS = {
    'citation-only' => 'world',
    'dark' => 'dark',
    'location-based' => 'world',
    'stanford' => 'world',
    'world' => 'world'
  }.freeze
  FILE_ACCESS = {
    'citation-only' => 'dark',
    'dark' => 'dark',
    'location-based' => 'location-based',
    'stanford' => 'stanford',
    'world' => 'world'
  }.freeze

  before_action :load_cocina_object, only: :apply

  def apply
    return type_error_response unless @cocina_object.dro? || @cocina_object.collection?
    return workflow_error_response unless current_workflow_state.in?(ALLOWED_WORKFLOW_STATES)

    CocinaObjectStore.save(updated_cocina_object)
    head :no_content
  end

  private

  def current_workflow_state
    WorkflowClientFactory
      .build
      .status(druid: @cocina_object.externalIdentifier, version: @cocina_object.version)
      .display_simplified
  end

  def type_error_response
    json_api_error(
      status: :bad_request,
      message: "#{@cocina_object.externalIdentifier} is a #{@cocina_object.class} and this type cannot currently have APO access defaults applied",
      title: 'Object cannot inherit APO access defaults'
    )
  end

  def workflow_error_response
    json_api_error(
      status: :unprocessable_entity,
      message: "#{@cocina_object.externalIdentifier} is in a state in which it cannot be modified (#{current_workflow_state}): " \
               'APO defaults can only be applied when an object is either registered or opened for versioning',
      title: 'Object cannot be modified in current state'
    )
  end

  def updated_cocina_object
    access_updated = @cocina_object.new(
      access: @cocina_object.access.new(default_access_from_apo)
    )
    return access_updated unless access_updated.dro? && access_updated.structural&.contains&.any?

    access_updated.new(
      structural: @cocina_object.structural.new(
        contains: @cocina_object.structural.contains.map do |file_set|
          file_set.new(
            structural: file_set.structural.new(
              contains: file_set.structural.contains.map do |file|
                file.new(file_properties(file: file))
              end
            )
          )
        end
      )
    )
  end

  def file_access_props
    %i[access controlledDigitalLending download readLocation]
  end

  def collection_access_props
    %i[access copyright license useAndReproductionStatement]
  end

  def file_properties(file:)
    updated_file_access = default_access_from_apo(file_level: true)

    { access: updated_file_access }.tap do |props|
      next if updated_file_access[:access] != 'dark'

      props[:administrative] = file.administrative.new(shelve: false)
    end
  end

  def default_access_from_apo(file_level: false)
    default_access = CocinaObjectStore.find(@cocina_object.administrative.hasAdminPolicy)
                                      .administrative
                                      .defaultAccess
                                      .to_h
                                      .with_indifferent_access

    if file_level
      return default_access.slice(*file_access_props)
                           .tap { |access| access[:access] = FILE_ACCESS[access[:access]] }
    end

    if @cocina_object.collection?
      return default_access.slice(*collection_access_props)
                           .tap { |access| access[:access] = COLLECTION_ACCESS[access[:access]] }
    end

    default_access
  end
end
