module AuthHelper
  def login
    user = Settings.DOR.SERVICE_USER
    pass = Settings.DOR.SERVICE_PASSWORD
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pass)
  end
end
