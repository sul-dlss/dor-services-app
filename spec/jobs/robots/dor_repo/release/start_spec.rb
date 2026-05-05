# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Release::Start, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Workflow::ProcessService).to receive(:update)
  end

  context 'when the object has a Folio catalog link' do
    let(:object) do
      build(:dro, id: druid).new(identification: {
                                   sourceId: 'sul:123',
                                   catalogLinks: [{ catalog: 'folio', catalogRecordId: 'in00000000001' }]
                                 })
    end

    it 'returns early without skipping any workflow steps' do
      perform
      expect(Workflow::ProcessService).not_to have_received(:update)
    end
  end

  context 'when the object has no Folio catalog link' do
    let(:object) { build(:dro, id: druid) }

    it 'skips update-marc and update-holdings workflow steps' do
      perform
      expect(Workflow::ProcessService).to have_received(:update).with(druid:, workflow_name: 'releaseWF',
                                                                      process: 'update-marc', status: 'skipped')
      expect(Workflow::ProcessService).to have_received(:update).with(druid:, workflow_name: 'releaseWF',
                                                                      process: 'update-holdings', status: 'skipped')
    end
  end
end
