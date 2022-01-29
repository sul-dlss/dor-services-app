# frozen_string_literal: true

# Applies the AdminPolicy defaults to a repository object
class AdminPolicyDefaultsController < ApplicationController
  before_action :load_item, only: :apply

  ALLOWED_WORKFLOW_STATES = %i[Registered Opened].freeze

  def apply
    return error_response unless current_workflow_state.in?(ALLOWED_WORKFLOW_STATES)

    @item.rightsMetadata.content = @item.admin_policy_object.defaultObjectRights.content
    @item.save!
    head :no_content
  end

  private

  def current_workflow_state
    WorkflowClientFactory.build
                         .status(druid: @item.pid, version: @item.current_version)
                         .display_simplified
  end

  def error_response
    json_api_error(
      status: :unprocessable_entity,
      message: "#{@item.pid} is in a state in which it cannot be modified (#{current_workflow_state}): " \
               'APO defaults can only be applied when an object is either registered or opened for versioning',
      title: 'Object cannot be modified in current state'
    )
  end
end
