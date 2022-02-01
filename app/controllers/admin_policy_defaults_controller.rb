# frozen_string_literal: true

# Applies the AdminPolicy defaults to a repository object
class AdminPolicyDefaultsController < ApplicationController
  ALLOWED_WORKFLOW_STATES = %w[Registered Opened].freeze

  before_action :load_cocina_object, only: :apply

  def apply
    return error_response unless current_workflow_state.in?(ALLOWED_WORKFLOW_STATES)

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

  def error_response
    json_api_error(
      status: :unprocessable_entity,
      message: "#{@cocina_object.externalIdentifier} is in a state in which it cannot be modified (#{current_workflow_state}): " \
               'APO defaults can only be applied when an object is either registered or opened for versioning',
      title: 'Object cannot be modified in current state'
    )
  end

  def updated_cocina_object
    @cocina_object.new(
      access: @cocina_object.access.new(**default_access_from_apo),
      structural: @cocina_object.structural.new(
        contains: @cocina_object.structural.contains.map do |file_set|
          file_set.new(
            structural: file_set.structural.new(
              contains: file_set.structural.contains.map do |file|
                file.new(
                  access: file.access.new(
                    default_access_from_apo.to_h.slice(*file_access_props)
                  )
                )
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

  def default_access_from_apo
    CocinaObjectStore
      .find(@cocina_object.administrative.hasAdminPolicy)
      .administrative
      .defaultAccess
  end
end
