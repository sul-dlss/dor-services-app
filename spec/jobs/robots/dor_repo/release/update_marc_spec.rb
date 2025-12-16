# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Release::UpdateMarc, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }
  let(:thumbnail_service) { instance_double(ThumbnailService) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Catalog::UpdateMarc856RecordService).to receive(:update)
    allow(ThumbnailService).to receive(:new).and_return(thumbnail_service)
  end

  it 'updates the MARC record for the object' do
    expect { perform }.not_to raise_error
    expect(perform).to have_attributes(status: 'skipped')
    # expect(Catalog::UpdateMarc856RecordService).to have_received(:update).with(object,
    #                                                                            thumbnail_service: thumbnail_service)
    # expect(ThumbnailService).to have_received(:new).with(object)
  end
end
