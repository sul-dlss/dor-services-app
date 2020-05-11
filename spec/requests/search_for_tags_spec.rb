# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Searching for tags' do
  before do
    TagLabel.create([
                      { tag: 'Project : EVIS' },
                      { tag: 'Project : EVIS : subtag' },
                      { tag: 'Professional : Work' },
                      { tag: 'Unrelated : foo' }
                    ])
  end

  it 'returns partial results' do
    get '/v1/administrative_tags/search?q=Pro', headers: { 'Authorization' => "Bearer #{jwt}" }
    expect(response.body).to eq '["Project : EVIS","Project : EVIS : subtag","Professional : Work"]'
  end
end
