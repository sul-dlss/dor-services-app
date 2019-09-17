# frozen_string_literal: true

module AuthHelper
  def login
    allow(controller).to receive(:check_auth_token)
  end

  def jwt
    JWT.encode(payload, Settings.dor.hmac_secret, 'HS256')
  end

  private

  def payload
    { sub: 'argo' }
  end
end
