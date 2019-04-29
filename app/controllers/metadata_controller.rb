# frozen_string_literal: true

# A controller to display derived metadata about an object
class MetadataController < ApplicationController
  before_action :load_item

  def dublin_core
    service = DublinCoreService.new(@item)
    render xml: service
  end
end
