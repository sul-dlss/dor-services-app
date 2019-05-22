# frozen_string_literal: true

module AuthHelper
  def login
    user = Settings.dor.service_user
    pass = Settings.dor.service_password
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pass)
  end
end
