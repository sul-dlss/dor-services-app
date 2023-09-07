# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationCsvConverter do
  let(:results) { described_class.convert(csv_string:) }

  let(:expected_cocina) do
    Cocina::Models.build_request(
      {
        cocinaVersion: Cocina::Models::VERSION,
        type: Cocina::Models::ObjectType.book,
        label: 'My new object',
        version: 1,
        access: { view: 'world', download: 'world', controlledDigitalLending: false },
        administrative: { hasAdminPolicy: 'druid:bc123df4567' },
        identification: { sourceId: 'foo:123' },
        structural: { isMemberOf: ['druid:bk024qs1808'] }
      }
    )
  end

  context 'when all values provided in CSV' do
    let(:csv_string) do
      <<~CSV
        administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
        druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
        xdruid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,world
      CSV
    end

    it 'returns result with model, workflow, and tags' do
      expect(results.size).to be 2
      expect(results.first[:cocina_request_object].success?).to be true
      expect(results.first[:cocina_request_object].value![:workflow]).to eq('accessionWF')
      expect(results.first[:cocina_request_object].value![:tags]).to eq(['csv : test', 'Project : two'])
      expect(results.first[:cocina_request_object].value![:model]).to eq(expected_cocina)
      expect(results.second[:cocina_request_object].success?).to be false
    end
  end
end
