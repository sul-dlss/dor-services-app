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
    ).new(structural:)
    Cocina::Models.with_metadata(dro, 'abc123', created: DateTime.parse('Wed, 01 Jan 2020 12:00:01 GMT'),
                                                modified: DateTime.parse('Thu, 04 Mar 2021 23:05:34 GMT'))
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
          'member_of_collection_ssim' => ['druid:bb777bb7777', 'druid:dd666dd6666'],
          'is_governed_by_ssim' => 'info:fedora/druid:vv888vv8888', # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
          'is_member_of_collection_ssim' => ['info:fedora/druid:bb777bb7777', 'info:fedora/druid:dd666dd6666'], # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532 # rubocop:disable Layout/LineLength
          'modified_latest_dtpsidv' => '2021-03-04T23:05:34Z',
          'created_at_dttsi' => '2020-01-01T12:00:01Z',
          'id' => 'druid:xx999xx9999',
          'trace_id_ss' => 'abc123'
        )
      end
    end

    context 'with no collections' do
      let(:structural) do
        {}
      end

      it 'makes a solr doc' do
        expect(doc).to eq(
          'obj_label_tesim' => 'item label',
          'current_version_ipsidv' => 4,
          'milestones_ssim' => %w[foo bar],
          'is_governed_by_ssim' => 'info:fedora/druid:vv888vv8888', # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
          'is_member_of_collection_ssim' => [], # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
          'governed_by_ssim' => 'druid:vv888vv8888',
          'member_of_collection_ssim' => [],
          'has_constituents_ssimdv' => nil,
          'modified_latest_dtpsidv' => '2021-03-04T23:05:34Z',
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
          'is_governed_by_ssim' => 'info:fedora/druid:vv888vv8888', # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
          'is_member_of_collection_ssim' => [], # TODO: Remove https://github.com/sul-dlss/dor-services-app/issues/5532
          'governed_by_ssim' => 'druid:vv888vv8888',
          'member_of_collection_ssim' => [],
          'modified_latest_dtpsidv' => '2021-03-04T23:05:34Z',
          'created_at_dttsi' => '2020-01-01T12:00:01Z',
          'id' => 'druid:xx999xx9999',
          'trace_id_ss' => 'abc123'
        )
      end
    end
  end
end
