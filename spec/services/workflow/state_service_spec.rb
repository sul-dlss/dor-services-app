# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::StateService do
  subject(:workflow_state) { described_class.new(druid:, version: nil) }

  let(:druid) { 'druid:xz456jk0987' }
  let(:workflow_state_batch_service) do
    instance_double(Workflow::StateBatchService, accessioned_druids:, accessioning_druids:, assembling_druids:)
  end
  let(:accessioned_druids) { [] }
  let(:accessioning_druids) { [] }
  let(:assembling_druids) { [] }

  before do
    allow(Workflow::StateBatchService).to receive(:new).and_return(workflow_state_batch_service)
  end

  describe '.accessioned?' do
    context 'when the object is accessioned' do
      let(:accessioned_druids) { [druid] }

      it 'returns true' do
        expect(workflow_state).to be_accessioned
      end
    end

    context 'when the object is not accessioned' do
      it 'returns false' do
        expect(workflow_state).not_to be_accessioned
      end
    end
  end

  describe '.accessioning?' do
    context 'when the object is accessioning' do
      let(:accessioning_druids) { [druid] }

      it 'returns true' do
        expect(workflow_state).to be_accessioning
      end
    end

    context 'when the object is not accessioning' do
      it 'returns false' do
        expect(workflow_state).not_to be_accessioning
      end
    end
  end

  describe '.assembling?' do
    context 'when the object is assembling' do
      let(:assembling_druids) { [druid] }

      it 'returns true' do
        expect(workflow_state).to be_assembling
      end
    end

    context 'when the object is not assembling' do
      it 'returns false' do
        expect(workflow_state).not_to be_assembling
      end
    end
  end
end
