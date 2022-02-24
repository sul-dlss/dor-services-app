# frozen_string_literal: true

# A controller to display datastreams for an object.
# This controller is intended to be temporary until we can decouple Argo's UX
# from the datastream abstraction.
class DatastreamsController < ApplicationController
  def index
    item = Dor.find(params[:object_id])
    result = item.datastreams
                 .reject { |name, instance| instance.new? || name == 'workflows' }
                 .values
                 .map { |ds| serialize_datastream(ds) }
    render json: result
  end

  def show
    item = Dor.find(params[:object_id])
    render xml: item.datastreams[params[:id]].content
  end

  private

  def serialize_datastream(datastream)
    version_id = datastream.versionID.nil? ? '0' : datastream.versionID.to_s.split('.').last
    { label: datastream.label, dsid: datastream.dsid, pid: datastream.pid,
      size: datastream.size, mimeType: datastream.mimeType, versionId: "v#{version_id}" }
  end
end
