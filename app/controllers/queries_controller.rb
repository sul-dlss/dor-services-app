# frozen_string_literal: true

# Responds to queries about objects
class QueriesController < ApplicationController
  before_action :load_item, only: [:collections]

  # Returns a list of collections this object is in.
  def collections
    # If we move to Valkyrie this can be find_inverse_references_by
    @collections = @item.collections.map { |collection| Cocina::Mapper.build(collection) }
  end
end
