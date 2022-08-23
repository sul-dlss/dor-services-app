# frozen_string_literal: true

# Responds to queries about the members of a collection
class MembersController < ApplicationController
  # Return the published members of this collection
  def index
    @members = MemberService.for(params[:object_id], only_published: true)
  end
end
