# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::BasicIndexer do
  let(:cocina) do
    dro = build(
      :dro,
      id: 'druid:xx999xx9999',
      admin_policy_id: 'druid:vv888vv8888',
      label: 'item label',
      version: 4
    ).new(structural:, access:)
    Cocina::Models.with_metadata(dro, 'abc123', created: DateTime.parse('Wed, 01 Jan 2020 12:00:01 GMT'),
                                                modified: DateTime.parse('Thu, 04 Mar 2021 23:05:34 GMT'))
  end

  let(:structural) { {} }

  let(:access) do
    {
      view: 'dark',
      download: 'none'
    }
  end

  before do
    allow(Indexing::WorkflowFields).to receive(:for).and_return({ 'milestones_ssim' => %w[foo bar] })
  end

  describe '#to_solr' do
    let(:indexer) do
      Indexing::Indexers::CompositeIndexer.new(
        described_class
      ).new(id: 'druid:ab123cd4567', cocina:, workflow_client: instance_double(Dor::Services::Client), trace_id:)
    end
    let(:doc) { indexer.to_solr }
    let(:trace_id) { 'abc123' }

    context 'with collections' do
      let(:structural) do
        { isMemberOf: ['druid:bb777bb7777', 'druid:dd666dd6666'] }
      end

      it 'makes a solr doc' do
        expect(doc).to eq(
          'obj_label_tesim' => 'item label',
          'current_version_ipsidv' => 4,
          'milestones_ssim' => %w[foo bar],
          'has_constituents_ssimdv' => nil,
          'governed_by_ssim' => 'druid:vv888vv8888',
          'bare_governed_by_ss' => 'vv888vv8888',
          'member_of_collection_ssim' => ['druid:bb777bb7777', 'druid:dd666dd6666'],
          'bare_member_of_collection_ssm' => %w[bb777bb7777 dd666dd6666],
          'created_at_dttsi' => '2020-01-01T12:00:01Z',
          'id' => 'druid:xx999xx9999',
          'trace_id_ss' => 'abc123'
        )
      end
    end

    context 'with no collections' do
      it 'makes a solr doc' do
        expect(doc).to eq(
          'obj_label_tesim' => 'item label',
          'current_version_ipsidv' => 4,
          'milestones_ssim' => %w[foo bar],
          'governed_by_ssim' => 'druid:vv888vv8888',
          'bare_governed_by_ss' => 'vv888vv8888',
          'member_of_collection_ssim' => [],
          'bare_member_of_collection_ssm' => [],
          'has_constituents_ssimdv' => nil,
          'created_at_dttsi' => '2020-01-01T12:00:01Z',
          'id' => 'druid:xx999xx9999',
          'trace_id_ss' => 'abc123'
        )
      end
    end

    context 'with constituents' do
      let(:structural) do
        { hasMemberOrders: [{ members: ['druid:bb777bb7777', 'druid:dd666dd6666'] }] }
      end

      it 'makes a solr doc' do
        expect(doc).to eq(
          'obj_label_tesim' => 'item label',
          'current_version_ipsidv' => 4,
          'milestones_ssim' => %w[foo bar],
          'has_constituents_ssimdv' => ['druid:bb777bb7777', 'druid:dd666dd6666'],
          'constituents_count_ips' => 2,
          'governed_by_ssim' => 'druid:vv888vv8888',
          'bare_governed_by_ss' => 'vv888vv8888',
          'member_of_collection_ssim' => [],
          'bare_member_of_collection_ssm' => [],
          'created_at_dttsi' => '2020-01-01T12:00:01Z',
          'id' => 'druid:xx999xx9999',
          'trace_id_ss' => 'abc123'
        )
      end
    end

    context 'when the object is dark' do
      it 'does not include the purl_ss field' do
        expect(doc.key?('purl_ss')).to be false
      end
    end

    context 'when the object is not dark' do
      let(:access) do
        {
          view: 'world',
          download: 'world'
        }
      end

      it 'includes the purl_ss field' do
        expect(doc['purl_ss']).to eq('https://purl.stanford.edu/xx999xx9999')
      end
    end

    context 'when an admin policy' do
      let(:cocina) do
        Cocina::Models.with_metadata(
          build(:admin_policy),
          'def456',
          created: DateTime.parse('Wed, 01 Jan 2020 12:00:01 GMT'),
          modified: DateTime.parse('Thu, 04 Mar 2021 23:05:34 GMT')
        )
      end

      it 'does not include the purl_ss field' do
        expect(doc.key?('purl_ss')).to be false
      end
    end
  end
end
