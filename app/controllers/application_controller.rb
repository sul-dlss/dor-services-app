# frozen_string_literal: true

# Base controller for the application.
class ApplicationController < ActionController::API
  include ActionController::MimeResponds

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

  def validate_from_openapi
    errors = spec_errors.to_a
    raise(Cocina::ValidationError, errors.pluck('error').join('; ')) if errors.any?
  end

  private

  def spec_errors
    verb = request.method.downcase
    return if %w[delete get].include?(verb) # no body to verify

    path = json_ref_for_path

    unless request.content_type == 'application/json'
      raise Cocina::ValidationError,
            '"Content-Type" request header must be set to "application/json".'
    end

    schema = YAML.load_file('openapi.yml')
    document = JSONSchemer.openapi(schema)
    document.ref("#/paths/#{path}/#{verb}/requestBody/content/application~1json/schema")
            .validate(JSON.parse(request.body.read))
  end

  def json_ref_for_path
    path = CGI.unescape(request.path).tr(' ', '+')
    path.gsub!(params[:object_id], '%7Bobject_id%7D') if params[:object_id]
    path.gsub!(params[:id], '%7Bid%7D') if params[:id]
    path.gsub('/', '~1')
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
  def load_cocina_object
    @cocina_object = CocinaObjectStore.find(params[:object_id] || params[:id])
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
end
