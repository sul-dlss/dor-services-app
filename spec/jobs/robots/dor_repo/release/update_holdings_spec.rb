# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Release::UpdateHoldings, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }

  let(:object) do
    build(:dro, id: druid).new(identification: {
                                 sourceId: 'sul:8832162',
                                 catalogLinks: [
                                   {
                                     catalog: 'folio',
                                     catalogRecordId: 'a123'
                                   }
                                 ]
                               })
  end

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Catalog::UpdateHoldingsService).to receive(:update)
    allow(RedisLock).to receive(:with_lock) do |*_args, &block|
      block.call
      true
    end
  end

  it 'updates the FOLIO holdings for the object' do
    expect { perform }.not_to raise_error
    expect(RedisLock).to have_received(:with_lock).with(key: 'update-holdings-a123', lock_timeout: 180)
    expect(Catalog::UpdateHoldingsService).to have_received(:update).with(object)
  end

  context 'when the object is an admin policy' do
    let(:object) { build(:admin_policy, id: druid) }

    it 'skips the object' do
      expect { perform }.not_to raise_error
      expect(RedisLock).not_to have_received(:with_lock)
      expect(Catalog::UpdateHoldingsService).not_to have_received(:update)
    end
  end

  context 'when the object has no FOLIO catalog link' do
    let(:object) do
      build(:dro, id: druid).new(identification: {
                                   sourceId: 'sul:8832162',
                                   catalogLinks: []
                                 })
    end

    it 'skips the object' do
      expect { perform }.not_to raise_error
      expect(RedisLock).not_to have_received(:with_lock)
      expect(Catalog::UpdateHoldingsService).not_to have_received(:update)
    end
  end

  context 'when getting a lock fails' do
    before do
      allow(RedisLock).to receive(:with_lock).and_return(false)
    end

    it 'raises' do
      expect { perform }.to raise_error(RedisLock::DeadLockError)
    end
  end
end
