# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Show single user version' do
  let(:druid) { 'druid:mx123qw2323' }

  let(:workflows) do
    instance_double(Indexing::Indexers::WorkflowsIndexer, to_solr: { 'wf_ssim' => ['accessionWF'] })
  end

  context 'when found' do
    before do
      repository_object = create(:repository_object, :with_repository_object_version, :closed,
                                 external_identifier: druid)
      create(:user_version, version: 1, repository_object_version: repository_object.versions.first)
      allow(Indexing::Indexers::WorkflowsIndexer).to receive(:new).and_return(workflows)
      allow(Indexing::WorkflowFields).to receive(:for).and_return({ milestones_ssim: %w[foo bar] })
    end

    it 'returns a 200' do
      get "/v1/objects/#{druid}/user_versions/1/solr",
          headers: { 'Authorization' => "Bearer #{jwt}" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(id: druid)
      expect(response.parsed_body).to include(rights_descriptions_ssim: ['world', 'dark (file)']) # TODO: Remove
      expect(response.parsed_body).to include(rights_descriptions_ssimdv: ['world', 'dark (file)'])
    end
  end
end
