# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show solr for an object version' do
  let(:object) { create(:repository_object, :with_repository_object_version, :closed) }
  let(:workflows) { instance_double(Indexing::Indexers::WorkflowsIndexer, to_solr: { 'wf_ssim' => ['accessionWF'] }) }

  before do
    allow(Indexing::Indexers::WorkflowsIndexer).to receive(:new).and_return(workflows)
    allow(Indexing::WorkflowFields).to receive(:for).and_return({ milestones_ssim: %w[foo bar] })
  end

  it 'returns a 200' do
    get "/v1/objects/#{object.external_identifier}/versions/1/solr",
        headers: { 'Authorization' => "Bearer #{jwt}" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(id: object.external_identifier)
    expect(response.parsed_body).to include(rights_descriptions_ssimdv: ['world', 'dark (file)'])
  end

  context 'with an object that has invalid cocina' do
    before do
      object.head_version.tap do |version|
        version.description['title'] =
          [{ 'value' => 'Test DRO', 'parallelValue' => [{ 'value' => 'Аԥышәара DRO' }, { 'value' => 'परीक्षण DRO' }] }]
        version.save!
      end
    end

    context 'when validate param is set to true (default value)' do
      it 'raises a Cocina validation error' do
        expect do
          get "/v1/objects/#{object.external_identifier}/versions/1/solr?validate=true",
              headers: { 'Authorization' => "Bearer #{jwt}" }
        end.to raise_error(Cocina::Models::ValidationError)
      end
    end

    context 'when validate param is set to false' do
      it 'returns a 200' do
        get "/v1/objects/#{object.external_identifier}/versions/1/solr?validate=false",
            headers: { 'Authorization' => "Bearer #{jwt}" }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include(id: object.external_identifier)
        expect(response.parsed_body).to include(display_title_ss: 'Test DRO')
      end
    end
  end

  context 'with an object that has *really* invalid cocina' do
    before do
      object.head_version.tap do |version|
        version.administrative['releaseTags'] = [
          {
            who: 'mjgiarlo',
            what: 'self',
            to: 'Searchworks',
            release: true
          }
        ]
        version.save!
      end
    end

    it 'returns a 200' do
      get "/v1/objects/#{object.external_identifier}/versions/1/solr?validate=true",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(id: object.external_identifier)
      expect(response.parsed_body).to include(display_title_ss: 'Test DRO')
    end
  end
end
