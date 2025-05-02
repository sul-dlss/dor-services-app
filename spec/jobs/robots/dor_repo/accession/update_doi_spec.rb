# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Accession::UpdateDoi, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:druid) { 'druid:zz000zz0001' }
  let(:robot) { described_class.new }
  let(:doi) { '10.80343/zz000zz0001' }
  let(:attributes) { { titles: [{ title: 'test deposit' }] } }

  let(:exportable) { true }
  let(:object) do
    object = build(:dro, id: druid)
    object.new(identification: object.identification.new(doi:))
  end
  let(:datacite_response_status) { 200 }

  before do
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(object)
    allow(Cocina::ToDatacite::Attributes).to receive_messages(exportable?: exportable, mapped_from_cocina: attributes)

    stub_request(:get, 'https://fake.datacite.example.com/dois/10.80343/zz000zz0001')
      .to_return(status: 404, headers: { 'Content-Type' => 'application/json' })

    stub_request(:put, 'https://fake.datacite.example.com/dois/10.80343/zz000zz0001')
      .with(
        body: '{"data":{"attributes":{"titles":[{"title":"test deposit"}]}}}'
      )
      .to_return(status: datacite_response_status, body: '', headers: {})
  end

  context 'when the object is an admin policy' do
    let(:object) { build(:admin_policy, id: druid) }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(perform.note).to eq 'DOIs are not supported on non-Item objects'
    end
  end

  context 'when the object is a collection policy' do
    let(:object) { build(:collection, id: druid) }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(perform.note).to eq 'DOIs are not supported on non-Item objects'
    end
  end

  context 'when the object does not have a doi' do
    let(:object) { build(:dro, id: druid) }

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(perform.note).to eq 'Object does not have a DOI'
    end
  end

  context 'when the object belongs to the SDR graveyard APO' do
    let(:object) do
      object = build(:dro, id: druid, admin_policy_id: Settings.graveyard_admin_policy.druid)
      object.new(identification: object.identification.new(doi:))
    end

    it 'skips the object' do
      expect(perform.status).to eq 'skipped'
      expect(perform.note).to eq 'Object belongs to the SDR graveyard APO'
    end
  end

  context 'when the object is not exportable' do
    let(:exportable) { false }

    it 'raises an error' do
      expect do
        perform
      end.to raise_error(RuntimeError, /Item requested a DOI be updated, but it doesn't meet all the preconditions/)
      expect(Cocina::ToDatacite::Attributes).to have_received(:exportable?).with(object)
    end
  end

  context 'when Datacite returns an error' do
    let(:datacite_response_status) { 500 }

    it 'raises an error' do
      expect { perform }.to raise_error(RuntimeError, /Error connecting to datacite/)
    end
  end

  context 'with no errors' do
    it 'succeeds' do
      expect { perform }.not_to raise_error
      expect(Cocina::ToDatacite::Attributes).to have_received(:mapped_from_cocina).with(object, url: nil)
    end
  end

  context 'when there is an existing DOI with a URL' do
    let(:url) { 'https://example.com/doi' }

    before do
      stub_request(:get, 'https://fake.datacite.example.com/dois/10.80343/zz000zz0001')
        .to_return(status: 200,
                   body: { data: { attributes: { url: } } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    it 'provides that url when generating attributes' do
      expect { perform }.not_to raise_error
      expect(Cocina::ToDatacite::Attributes).to have_received(:mapped_from_cocina).with(object, url:)
    end
  end
end
