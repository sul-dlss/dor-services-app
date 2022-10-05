# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  rescue_from ActionController::ParameterMissing do |exception|
    render json: {
      errors: [
        { title: 'bad request', detail: exception.message }
      ]
    }, status: :bad_request
  end

  before_action :check_auth_token

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

  # Adds headers from the cocina object.
  def add_headers(cocina_object)
    headers['X-Created-At'] = cocina_object.created.httpdate
    headers['Last-Modified'] = cocina_object.modified.httpdate
    headers['ETag'] = "W/\"#{cocina_object.lock}\""
  end
end
