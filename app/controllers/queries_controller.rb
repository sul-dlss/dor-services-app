# frozen_string_literal: true

# Responds to queries about objects
class QueriesController < ApplicationController
  before_action :load_cocina_object, only: %i[collections collections_for_registration]

  # Returns a list of collections this object is in.
  def collections
    @collections = CocinaObjectStore.find_collections_for(@cocina_object).map do |collection_object|
      Cocina::Models.without_metadata(collection_object)
    end
  end

  # Returns a list of collections the AdminPolicy allows for registration
  def collections_for_registration
    @collections = CocinaObjectStore.find_collections_for_registration(@cocina_object).map do |collection_object|
      Cocina::Models.without_metadata(collection_object)
    end
  end
end
