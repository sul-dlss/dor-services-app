class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  http_basic_authenticate_with name: Dor::Config.dor.service_user, password: Dor::Config.dor.service_password

  protected
  
  def proxy_rest_client_response(response)
    render status: response.code, content_type: response.headers[:content_type], body: response.body
  end
end
