# frozen_string_literal: true

# Applies the AdminPolicy defaults to a repository object
class AdminPolicyDefaultsController < ApplicationController
  before_action :load_cocina_object, only: :apply

  def apply
    CocinaObjectStore.save(updated_cocina_object)
    head :no_content
  end

  private

  def updated_cocina_object
    @cocina_object.new(access: @cocina_object.access.new(**default_access_from_apo))
  end

  def default_access_from_apo
    CocinaObjectStore
      .find(@cocina_object.administrative.hasAdminPolicy)
      .administrative
      .defaultAccess
  end
end
