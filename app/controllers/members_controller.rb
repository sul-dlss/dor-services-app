# frozen_string_literal: true

# Responds to queries about the members of a collection
class MembersController < ApplicationController
  # Return the members of this collection
  def index
    @members = RepositoryObject.currently_members_of_collection(params[:object_id])
  end
end
