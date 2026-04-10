# frozen_string_literal: true

# Base controller for the application.
class ApplicationController < ActionController::API
  include ActionController::MimeResponds
  include JSONSchemer::Rails::Controller

  rescue_from ActionController::ParameterMissing do |exception|
    render json: {
      errors: [
        { title: 'bad request', detail: exception.message }
      ]
    }, status: :bad_request
  end

  # Disabling in development so that Graphiql can reach graphql endpoint.
  before_action :check_auth_token, unless: -> { Rails.env.development? }

  TOKEN_HEADER = 'Authorization'

  def json_api_error(status:, message:, title: nil, meta: nil)
    status_code = Rack::Utils.status_code(status)
    render status:,
           content_type: 'application/vnd.api+json',
           json: {
             errors: [
               {
                 status: status_code.to_s,
                 title: title || Rack::Utils::HTTP_STATUS_CODES[status_code],
                 detail: message
               }.tap do |h|
                 h[:meta] = meta if meta.present?
               end
             ]
           }
  end

  private

  # This overrides JSONSchemer::Rails::Controller to provide our ref_resolver
  def openapi_validator
    @openapi_validator ||= JSONSchemer::Rails::OpenApiValidator.new(request, ref_resolver:)
  end

  # Resolves the cocina-models copy of openapi.yml
  def ref_resolver
    @ref_resolver ||= proc { |url|
      raise "Unknown Reference #{url}" unless url.to_s.starts_with? 'https://raw.githubusercontent.com/sul-dlss/cocina-models'

      Cocina::Models::Validators::JsonSchemaValidator.document
    }
  end

  # Ensure a valid token is present, or renders "401: Not Authorized"
  def check_auth_token
    token = decoded_auth_token
    return render json: { error: 'Not Authorized' }, status: :unauthorized unless token

    Honeybadger.context(invoked_by: token[:sub])
  end

  def decoded_auth_token
    @decoded_auth_token ||=
      begin
        body = JWT.decode(http_auth_header, Settings.dor.hmac_secret, true, algorithm: 'HS256').first
        ActiveSupport::HashWithIndifferentAccess.new body
      rescue StandardError
        nil
      end
  end

  def http_auth_header
    return if request.headers[TOKEN_HEADER].blank?

    request.headers[TOKEN_HEADER].split.last
  end

  # @raise [CocinaObjectStore::CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def load_cocina_object(**cocina_build_params)
    @cocina_object = CocinaObjectStore.find(params[:object_id] || params[:id], **cocina_build_params)
  end

  def cocina_build_params
    boolean_param(
      params.permit(:validate).to_h.symbolize_keys,
      :validate
    )
  end

  # @raise [CocinaObjectStore::CocinaObjectNotFoundError] raised when the requested Cocina object is not found.
  def check_cocina_object_exists
    CocinaObjectStore.exists!(params[:object_id] || params[:id])
  end

  # Adds headers from the cocina object.
  def add_headers(cocina_object)
    headers['X-Created-At'] = cocina_object.created.httpdate
    headers['Last-Modified'] = cocina_object.modified.httpdate
    headers['ETag'] = "W/\"#{cocina_object.lock}\""
  end

  def boolean_param(params_hash, key)
    params_hash[key] = ActiveModel::Type::Boolean.new.cast(params_hash[key]) if params_hash.key?(key)
    params_hash
  end
end
