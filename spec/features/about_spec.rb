require 'rails_helper'

RSpec.describe '/v1/about' do
  it 'handles simple ping requests to /about' do
    visit '/v1/about'
    expect(page).to have_content(/Version: \d\..*$/)
  end
end
