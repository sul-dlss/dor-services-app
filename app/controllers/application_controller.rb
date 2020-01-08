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

  # Since Basic auth was already using the Authorization header, we used something
  # non-standard:
  OLD_TOKEN_HEADER = 'X-Auth'
  TOKEN_HEADER = 'Authorization'

  private

  # Ensure a valid token is present, or renders "401: Not Authorized"
  def check_auth_token
    token = decoded_auth_token
    return render json: { error: 'Not Authorized' }, status: :unauthorized unless token

    Honeybadger.context(invoked_by: token[:sub])
    return unless request.headers[OLD_TOKEN_HEADER]

    Honeybadger.notify("Warning: Deprecated authorization header '#{OLD_TOKEN_HEADER}' was provided, but '#{TOKEN_HEADER}' is expected")
  end

  def decoded_auth_token
    @decoded_auth_token ||= begin
      body = JWT.decode(http_auth_header, Settings.dor.hmac_secret, true, algorithm: 'HS256').first
      HashWithIndifferentAccess.new body
                            rescue StandardError
                              nil
    end
  end

  def http_auth_header
    return if request.headers[OLD_TOKEN_HEADER].blank? && request.headers[TOKEN_HEADER].blank?

    field = request.headers[TOKEN_HEADER] || request.headers[OLD_TOKEN_HEADER]
    field.split(' ').last
  end

  def load_item
    @item = Dor.find(params[:object_id] || params[:id])
  end
end
