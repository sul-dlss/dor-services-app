module AuthHelper
  def login
    user = Dor::Config.dor.service_user
    pass = Dor::Config.dor.service_password
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, pass)
  end  
end
