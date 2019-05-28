# frozen_string_literal: true

module AuthHelper
  def login
    allow(controller).to receive(:check_auth_token)
  end
end
