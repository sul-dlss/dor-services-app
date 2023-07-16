# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateOrcidWorkJob do
  subject(:perform) do
    described_class.perform_now(cocina_item.to_json)
  end

  let(:cocina_item) do
    build(:dro, id: 'druid:bc234fg5678').new(
      identification: {
        doi: '10.25740/bc123df4567',
        sourceId: 'sul:123456'
      },
      description: {
        title: [
          {
            value: 'Strategies for Digital Library Migration'
          }
        ],
        purl: 'https://purl.stanford.edu/bc234fg5678',
        contributor: [
          {
            name: [
              {
                value: 'Justin Littman'
              }
            ],
            type: 'person',
            identifier: identifiers
          }
        ]
      }
    )
  end
  let(:identifiers) do
    [
      {
        value: '0000-0003-3437-349X',
        type: 'ORCID',
        source: {
          uri: 'https://sandbox.orcid.org'
        }
      }
    ]
  end

  let(:mais_orcid_client) { instance_double(MaisOrcidClient, fetch_orcid_user: orcid_user) }
  let(:orcid_client) { instance_double(SulOrcidClient, add_work: '12345', update_work: true) }

  let(:orcid_user) do
    MaisOrcidClient::OrcidUser.new(
      sunetid: 'jlittman',
      orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X',
      scope: ['/read-limited', '/activities/update', '/person/update'],
      access_token: 'FAKE-294e-4bc8-8afd-96315b06ae04'
    )
  end

  let(:work) do
    { contributors: { contributor: [{ 'contributor-orcid': { host: 'orcid.org',
                                                             path: '0000-0003-3437-349X',
                                                             uri: 'https://sandbox.orcid.org/0000-0003-3437-349X' },
                                      'credit-name': { value: 'Justin Littman' } }] },
      country: { value: 'US' },
      'external-ids': { 'external-id': [{ 'external-id-relationship': 'self',
                                          'external-id-type': 'uri',
                                          'external-id-url': { value: 'https://purl.stanford.edu/bc234fg5678' },
                                          'external-id-value': 'https://purl.stanford.edu/bc234fg5678' },
                                        { 'external-id-relationship': 'self',
                                          'external-id-type': 'doi',
                                          'external-id-url': { value: 'https://doi.org/10.25740/bc123df4567' },
                                          'external-id-value': '10.25740/bc123df4567' }] },
      'language-code': 'en',
      title: { title: { value: 'Strategies for Digital Library Migration' } },
      type: 'other',
      url: 'https://purl.stanford.edu/bc234fg5678' }
  end

  before do
    allow(MaisOrcidClient).to receive(:configure).and_return(mais_orcid_client)
    allow(SulOrcidClient).to receive(:configure).and_return(orcid_client)
  end

  context 'when adding a work' do
    it 'creates orcid work and AR orcid work' do
      perform
      expect(mais_orcid_client).to have_received(:fetch_orcid_user).with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X')
      expect(orcid_client).to have_received(:add_work)
        .with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', work:, token: 'FAKE-294e-4bc8-8afd-96315b06ae04')
      ar_orcid_work = OrcidWork.find_by(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', druid: 'druid:bc234fg5678')
      expect(ar_orcid_work.put_code).to eq('12345')
      expect(ar_orcid_work.md5).to eq('78aa93d1819c1bf3c7a8dceba861c613')
    end
  end

  context 'when updating a work' do
    let(:ar_orcid_work) { OrcidWork.create(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', druid: 'druid:bc234fg5678', put_code: '45678', md5: 'd41d8cd98f00b204e9800998ecf8427e') }

    it 'updates orcid work and AR orcid work' do
      expect { perform }.to change { ar_orcid_work.reload.md5 }.to('78aa93d1819c1bf3c7a8dceba861c613')
      expect(mais_orcid_client).to have_received(:fetch_orcid_user).with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X')
      expect(orcid_client).to have_received(:update_work)
        .with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', work:, token: 'FAKE-294e-4bc8-8afd-96315b06ae04', put_code: '45678')
    end
  end

  context 'when work has not changed' do
    let(:ar_orcid_work) { OrcidWork.create(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X', druid: 'druid:bc234fg5678', put_code: '45678', md5: '78aa93d1819c1bf3c7a8dceba861c613') }

    it 'does nothing' do
      expect { perform }.not_to(change { ar_orcid_work })
      expect(mais_orcid_client).to have_received(:fetch_orcid_user).with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X')
      expect(orcid_client).not_to have_received(:update_work)
    end
  end

  context 'when orcid user does not have write permissions' do
    let(:orcid_user) do
      MaisOrcidClient::OrcidUser.new(
        sunetid: 'jlittman',
        orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X',
        scope: ['/read-limited'],
        access_token: 'FAKE-294e-4bc8-8afd-96315b06ae04'
      )
    end

    it 'does nothing' do
      expect { perform }.not_to(change(OrcidWork, :count))
      expect(mais_orcid_client).to have_received(:fetch_orcid_user).with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X')
      expect(orcid_client).not_to have_received(:update_work)
    end
  end

  context 'when orcid user not found' do
    before do
      allow(mais_orcid_client).to receive(:fetch_orcid_user).and_return(nil)
    end

    it 'does nothing' do
      expect { perform }.not_to(change(OrcidWork, :count))
      expect(mais_orcid_client).to have_received(:fetch_orcid_user).with(orcidid: 'https://sandbox.orcid.org/0000-0003-3437-349X')
      expect(orcid_client).not_to have_received(:update_work)
    end
  end

  context 'when no contributors with orcids' do
    let(:identifiers) { [] }

    it 'does nothing' do
      expect { perform }.not_to(change(OrcidWork, :count))
      expect(mais_orcid_client).not_to have_received(:fetch_orcid_user)
      expect(orcid_client).not_to have_received(:update_work)
    end
  end
end
