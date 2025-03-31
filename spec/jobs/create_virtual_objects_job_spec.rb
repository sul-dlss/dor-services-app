# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateVirtualObjectsJob do
  let(:constituent1_id) { 'druid:constituent1' }
  let(:constituent2_id) { 'druid:constituent2' }
  let(:virtual_object_id) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:service) { instance_double(ConstituentService, add: nil) }
  let(:virtual_objects) { [{ virtual_object_id:, constituent_ids: [constituent1_id, constituent2_id] }] }

  before do
    allow(ConstituentService).to receive(:new)
      .with(virtual_object_druid: virtual_object_id).and_return(service)
    allow(BackgroundJobResult).to receive(:find).and_return(result)
    allow(result).to receive(:processing!)
  end

  context 'with no errors' do
    before do
      described_class.perform_now(virtual_objects:,
                                  background_job_result: result)
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the constituent service to do the virtual object creation' do
      expect(service).to have_received(:add).with(constituent_druids: [constituent1_id, constituent2_id]).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has no output' do
      expect(result.output).to be_blank
    end
  end

  context 'with errors returned by constituent service' do
    before do
      allow(service).to receive(:add).and_return(virtual_object_id => ['One thing was not combinable', 'And another'])
      described_class.perform_now(virtual_objects:,
                                  background_job_result: result)
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the constituent service to do the virtual object creation' do
      expect(service).to have_received(:add).with(constituent_druids: [constituent1_id, constituent2_id]).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has output with errors' do
      expect(result.output[:errors].first[virtual_object_id]).to contain_exactly('One thing was not combinable',
                                                                                 'And another')
    end
  end

  context 'with a mix of errors and successful results' do
    let(:other_constituent1_id) { 'druid:bar' }
    let(:other_constituent2_id) { 'druid:baz' }
    let(:other_virtual_object_id) { 'druid:foo' }
    let(:virtual_objects) do
      [
        { virtual_object_id:, constituent_ids: [constituent1_id, constituent2_id] },
        { virtual_object_id: other_virtual_object_id, constituent_ids: [other_constituent1_id, other_constituent2_id] }
      ]
    end

    before do
      allow(ConstituentService).to receive(:new)
        .with(virtual_object_druid: other_virtual_object_id).and_return(service)
      allow(service).to receive(:add).and_return(nil,
                                                 virtual_object_id => ['One thing was not combinable', 'And another'])
      described_class.perform_now(virtual_objects:,
                                  background_job_result: result)
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the constituent service to do the virtual object creation' do
      expect(service).to have_received(:add).with(constituent_druids: [constituent1_id, constituent2_id]).once
      expect(service).to have_received(:add).with(constituent_druids: [other_constituent1_id,
                                                                       other_constituent2_id]).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has output with errors' do
      expect(result.output[:errors].first[virtual_object_id]).to contain_exactly('One thing was not combinable',
                                                                                 'And another')
    end
  end
end
