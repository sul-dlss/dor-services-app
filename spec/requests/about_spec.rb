# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/v1/about' do
  it 'handles simple ping requests to /about' do
    get '/v1/about'
    expect(response.body).not_to match(/Version: \d\..*$/)
  end
end
