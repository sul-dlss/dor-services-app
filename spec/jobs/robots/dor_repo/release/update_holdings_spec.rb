# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Release::UpdateHoldings, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  let(:object) { build(:dro, id: druid) }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Catalog::UpdateHoldingsService).to receive(:update)
  end

  it 'updates the FOLIO holdings for the object' do
    expect { perform }.not_to raise_error
    expect(Catalog::UpdateHoldingsService).to have_received(:update).with(object)
  end
end
