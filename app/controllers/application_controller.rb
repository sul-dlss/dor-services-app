# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include ActionController::MimeResponds

  http_basic_authenticate_with name: Settings.DOR.SERVICE_USER,
                               password: Settings.DOR.SERVICE_PASSWORD

  before_action :check_auth_token

  # Since Basic auth is already using the Authorization header, we'll use something
  # non-standard:
  TOKEN_HEADER = 'X-Auth'

  private

  # In the transition period, we are going to check auth tokens, but we won't
  # require them.  We will continue to use BasicAuth.
  # Later we will ensurer that the tokens are present and remove BasicAuth
  def check_auth_token
    token = decoded_auth_token
    Honeybadger.context(invoked_by: token[:sub]) if token
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
    if request.headers[TOKEN_HEADER].blank?
      Honeybadger.notify("no #{TOKEN_HEADER} token was provided by #{request.remote_ip}")
      return
    end

    request.headers[TOKEN_HEADER].split(' ').last
  end

  def proxy_rest_client_response(response)
    render status: response.code, content_type: response.headers[:content_type], body: response.body
  end

  def load_item
    @item = Dor.find(params[:object_id] || params[:id])
  end
end
