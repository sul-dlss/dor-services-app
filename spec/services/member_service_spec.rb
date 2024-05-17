# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberService do
  let(:members) { described_class.for(collection_druid, exclude_opened:, only_published:) }

  let(:collection_druid) { 'druid:bc123df4567' }
  let(:exclude_opened) { false }
  let(:only_published) { false }

  let(:repository_object1) { create(:repository_object) }
  let(:repository_object2) { create(:repository_object) }

  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    # Opened
    repository_object_version1 = create(:repository_object_version, version: 2, is_member_of: [collection_druid], repository_object: repository_object1)
    repository_object1.update!(head_version: repository_object_version1, opened_version: repository_object_version1)

    # Closed
    repository_object_version2 = create(:repository_object_version, version: 2, is_member_of: [collection_druid], repository_object: repository_object2, closed_at: Time.current)
    repository_object2.update!(head_version: repository_object_version2, last_closed_version: repository_object_version2, opened_version: nil)

    # Not a member
    create(:repository_object)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.for' do
    context 'when collection has members' do
      it 'returns members' do
        expect(members).to contain_exactly(repository_object1.external_identifier, repository_object2.external_identifier)
      end
    end

    context 'when collection has no members' do
      it 'returns no members' do
        expect(described_class.for('druid:cc123df4568')).to be_empty
      end
    end

    context 'when excluding open members' do
      let(:exclude_opened) { true }

      it 'returns members' do
        expect(members).to eq [repository_object2.external_identifier]
      end
    end

    context 'when only published members' do
      let(:only_published) { true }

      before do
        allow(workflow_client).to receive(:lifecycle).with(druid: repository_object1.external_identifier, milestone_name: 'published', version: 2).and_return(true)
        allow(workflow_client).to receive(:lifecycle).with(druid: repository_object2.external_identifier, milestone_name: 'published', version: 2).and_return(false)
      end

      it 'returns members' do
        expect(members).to eq [repository_object1.external_identifier]
      end
    end
  end
end
