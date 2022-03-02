# frozen_string_literal: true

# Responds to queries about the members of a collection
class MembersController < ApplicationController
  # Return the published members of this collection
  def index
    query = "is_member_of_collection_ssim:\"info:fedora/#{params[:object_id]}\" published_dttsim:[* TO *]"
    args = {
      fl: 'id,objectType_ssim',
      rows: 100_000_000
    }
    @members = SolrService.query query, args
  end
end
