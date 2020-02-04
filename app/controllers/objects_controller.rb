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
    render status: :conflict, plain: e.message
  end

  rescue_from(Dry::Struct::Error) do |e|
    render status: :internal_server_error, plain: e.message
  end

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :internal_server_error, plain: e.message
  end

  # Register new objects in DOR
  def create
    begin
      reg_response = RegistrationService.create_from_request(create_params, event_factory: EventFactory)
    rescue ArgumentError => e
      return render status: :unprocessable_entity, plain: e.message
    end

    respond_to do |format|
      format.all { render status: :created, location: reg_response.location, plain: reg_response.to_txt }
      format.json { render status: :created, location: reg_response.location, json: reg_response }
    end
  end

  def show
    render json: Cocina::Mapper.build(@item)
  end

  # called from Argo, the accessionWF and from the releaseWF.
  # Takes an optional 'workflow' argument, which will call back to
  # the 'publish-complete' step of that workflow if provided
  def publish
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'publish_request_received', data: { background_job_result_id: result.id })

    PublishJob.perform_later(druid: params[:id], background_job_result: result, workflow: params[:workflow])
    head :created, location: result
  end

  def preserve
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'preserve_request_received', data: { background_job_result_id: result.id })

    PreserveJob.perform_later(druid: params[:id], background_job_result: result)
    head :created, location: result
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

  def proxy_faraday_response(response)
    render status: response.status, content_type: response.headers['Content-Type'], body: response.body
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
