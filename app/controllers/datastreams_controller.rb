# frozen_string_literal: true

# A controller to display datastreams for an object.
# This controller is intended to be temporary until we can decouple Argo's UX
# from the datastream abstraction.
class DatastreamsController < ApplicationController
  before_action :load_item

  def index
    result = @item.datastreams
                  .reject { |name, instance| instance.new? || name == 'workflows' }
                  .values
                  .map { |ds| { label: ds.label, dsid: ds.dsid, pid: ds.pid, size: ds.size, mimeType: ds.mimeType } }
    render json: result
  end

  def show
    render xml: @item.datastreams[params[:id]].content
  end
end
