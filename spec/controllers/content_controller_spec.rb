# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentController do
  before do
    login
    allow(Settings.content).to receive(:content_base_dir).and_return(File.join(FIXTURES_PATH, 'dor_workspace'))
  end

  describe '#list' do
    it 'lists the files in the object directory' do
      get :list, params: { id: 'ab123cd4567' }
      data = JSON.parse(response.body)

      expect(data['items'].length).to eq 1
      expect(data['items'].first['id']).to eq 'a'
    end

    it 'sends a 404 if the object directory does not exist' do
      get :list, params: { id: 'zy987xw6543' }

      expect(response.status).to eq 404
    end
  end

  describe '#read' do
    it 'retrieves the contents of the given file' do
      get :read, params: { id: 'ab123cd4567', path: 'a' }

      expect(response.body).to eq "a\n"
    end

    it 'sends a 404 if the file does not exist' do
      get :read, params: { id: 'ab123cd4567', path: 'a/b/c' }

      expect(response.status).to eq 404
    end

    it 'sends a 404 on HEAD requests of the file does not exist' do
      head :read, params: { id: 'ab123cd4567', path: 'a/b/c' }

      expect(response.status).to eq 404
    end
  end
end
