# frozen_string_literal: true

# Applies the AdminPolicy defaults to a repository object
class AdminPolicyDefaultsController < ApplicationController
  before_action :load_cocina_object, only: :apply

  def apply
    ApplyAdminPolicyDefaults.apply(cocina_object: @cocina_object)
    head :no_content
  rescue ApplyAdminPolicyDefaults::UnsupportedObjectTypeError => e
    json_api_error(status: :bad_request, message: e.message, title: 'Object cannot inherit APO access defaults')
  rescue ApplyAdminPolicyDefaults::UnsupportedWorkflowStateError => e
    json_api_error(status: :unprocessable_content, message: e.message, title: 'Object cannot be modified in current state')
  end
end
