# frozen_string_literal: true

# Responds to queries about the members of a collection
class MembersController < ApplicationController
  # Return the published members of this collection
  def index
    solr_params = {
      q: "is_member_of_collection_ssim:\"#{params[:id]}\" published_dttsim:[* TO *]",
      wt: :json,
      fl: 'id,objectType_ssim',
      rows: 100_000_000
    }
    response = ActiveFedora::SolrService.instance.conn.get 'select', params: solr_params
    @members = response['response']['docs']
  end
end
