# frozen_string_literal: true

# Responds to queries about objects
class QueriesController < ApplicationController
  before_action :load_cocina_object, only: [:collections]

  # Returns a list of collections this object is in.
  def collections
    # isMemberOf may be nil, in which case we want to return an empty array
    @collections = Array(@cocina_object.structural.isMemberOf).map do |collection_id|
      CocinaObjectStore.find(collection_id)
    end
  end
end
