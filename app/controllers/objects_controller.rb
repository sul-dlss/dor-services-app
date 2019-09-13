# frozen_string_literal: true

class ObjectsController < ApplicationController
  before_action :load_item, except: [:create]

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  rescue_from(Dor::ParameterError) do |e|
    render status: :bad_request, plain: e.message
  end

  rescue_from(Dor::DuplicateIdError) do |e|
    render status: :conflict, plain: e.message, location: object_location(e.pid)
  end

  rescue_from(DublinCoreService::CrosswalkError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  # Register new objects in DOR
  def create
    Rails.logger.info(params.inspect)
    begin
      reg_response = RegistrationService.create_from_request(create_params)
    rescue ArgumentError => e
      return render status: :unprocessable_entity, plain: e.message
    end
    Rails.logger.info(reg_response)
    pid = reg_response[:pid]

    respond_to do |format|
      format.all { render status: :created, location: object_location(pid), plain: Dor::RegistrationResponse.new(reg_response).to_txt }
      format.json { render status: :created, location: object_location(pid), json: Dor::RegistrationResponse.new(reg_response) }
    end
  end

  # TODO: Remove this once Argo, in stage and prod, uses a version of dor-services-client that no longer hits this endpoint
  # Handles updates to the record.
  # Presently this only needs to handle the merge object use case.
  # Do this by providing: constituent_ids => ['druid:123', 'druid:345']
  def update
    # validate that the constituent_ids parameter is an present, raises ActionController::ParameterMissing
    params.require(:constituent_ids)
    filtered_params = params.permit(constituent_ids: [])
    raise ActionController::ParameterMissing, 'constituent_ids must be an array' unless filtered_params[:constituent_ids]

    # Update the constituent relationship
    errors = ConstituentService.new(parent_druid: params[:id]).add(child_druids: filtered_params[:constituent_ids])

    return render json: { errors: errors }, status: :unprocessable_entity if errors

    head :no_content
  end

  def show
    render json: Cocina::Mapper.build(@item)
  end

  def publish
    PublishMetadataService.publish(@item)
    head :created
  end

  def update_marc_record
    Dor::UpdateMarcRecordService.new(@item).update
    head :created
  end

  # This endpoint is called by the goobi-notify process in the goobiWF
  # (code in https://github.com/sul-dlss/common-accessioning/blob/master/lib/robots/dor_repo/goobi/goobi_notify.rb)
  # This proxies a request to the Goobi server and proxies it's response to the client.
  def notify_goobi
    response = Dor::Goobi.new(@item).register
    return render status: :conflict, plain: response.body if response.status == 409

    proxy_faraday_response(response)
  end

  # You can post a release tag as JSON in the body to add a release tag to an item.
  # If successful it will return a 201 code, otherwise the error that occurred will bubble to the top
  #
  # 201
  def release_tags
    request.body.rewind
    body = request.body.read
    raw_params = JSON.parse body # This should produce a hash in valid release tag form=
    raw_params.symbolize_keys!

    if raw_params.key?(:release) && (raw_params[:release] == true || raw_params[:release] == false)
      ReleaseTags.create(@item, raw_params.slice(:release, :what, :to, :who, :when))
      @item.save
      head :created
    else
      render status: :bad_request, plain: "A release attribute is required in the JSON, and its value must be either 'true' or 'false'. You sent '#{raw_params[:release]}'"
    end
  end

  private

  def fedora_base
    URI.parse(Dor::Config.fedora.safeurl.sub(%r{/*$}, '/'))
  end

  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end

  def create_params
    params.to_unsafe_h.merge(body_params)
  end

  def body_params
    case request.content_type
    when 'application/xml', 'text/xml'
      Hash.from_xml(request.body.read)
    when 'application/json', 'text/json'
      JSON.parse(request.body.read)
    else
      {}
    end
  end
end
