# frozen_string_literal: true

# Applies the AdminPolicy defaults to a repository object
class AdminPolicyDefaultsController < ApplicationController
  before_action :load_item, only: :apply

  def apply
    @item.rightsMetadata.content = @item.admin_policy_object.defaultObjectRights.content
    @item.save!
    head :no_content
  end
end
