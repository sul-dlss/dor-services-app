# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberService do
  let(:members) { described_class.for(collection_druid, exclude_opened:, only_published:) }

  let(:collection_druid) { 'druid:bc123df4567' }
  let(:exclude_opened) { false }
  let(:only_published) { false }

  let!(:dro1) { create(:ar_dro, isMemberOf: [collection_druid]) }
  let!(:dro2) { create(:ar_dro, isMemberOf: [collection_druid]) }

  let(:workflow_client) { instance_double(Dor::Workflow::Client) }

  before do
    # Not a member
    create(:ar_dro)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.for' do
    context 'when collection has members' do
      it 'returns members' do
        expect(members).to contain_exactly(dro1.external_identifier, dro2.external_identifier)
      end
    end

    context 'when collection has no members' do
      it 'returns no members' do
        expect(described_class.for('druid:cc123df4568')).to be_empty
      end
    end

    context 'when excluding open members' do
      let(:exclude_opened) { true }

      before do
        allow(workflow_client).to receive(:active_lifecycle).with(
          druid: dro1.external_identifier,
          milestone_name: 'opened',
          version: 1
        ).and_return(true)
        allow(workflow_client).to receive(:active_lifecycle).with(
          druid: dro2.external_identifier,
          milestone_name: 'opened',
          version: 1
        ).and_return(false)
      end

      it 'returns members' do
        expect(members).to eq [dro2.external_identifier]
      end
    end

    context 'when only published members' do
      let(:only_published) { true }

      before do
        allow(workflow_client).to receive(:lifecycle).with(druid: dro1.external_identifier, milestone_name: 'published', version: 1).and_return(true)
        allow(workflow_client).to receive(:lifecycle).with(druid: dro2.external_identifier, milestone_name: 'published', version: 1).and_return(false)
      end

      it 'returns members' do
        expect(members).to eq [dro1.external_identifier]
      end
    end
  end
end
