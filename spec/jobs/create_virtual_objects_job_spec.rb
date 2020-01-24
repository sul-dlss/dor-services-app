# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateVirtualObjectsJob, type: :job do
  let(:child1_id) { 'druid:child1' }
  let(:child2_id) { 'druid:child2' }
  let(:parent_id) { 'druid:mk420bs7601' }
  let(:result) { create(:background_job_result) }
  let(:service) { instance_double(ConstituentService, add: nil) }
  let(:virtual_objects) { [{ parent_id: parent_id, child_ids: [child1_id, child2_id] }] }

  before do
    allow(ConstituentService).to receive(:new)
      .with(parent_druid: parent_id, event_factory: EventFactory).and_return(service)
    allow(BackgroundJobResult).to receive(:find).and_return(result)
    allow(result).to receive(:processing!)
  end

  context 'with no errors' do
    before do
      described_class.perform_now(virtual_objects: virtual_objects,
                                  background_job_result: result)
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the constituent service to do the virtual object creation' do
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id]).once
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
      allow(service).to receive(:add).and_return(parent_id => ['One thing was not combinable', 'And another'])
      described_class.perform_now(virtual_objects: virtual_objects,
                                  background_job_result: result)
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the constituent service to do the virtual object creation' do
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id]).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has output with errors' do
      expect(result.output[:errors].first[parent_id]).to match_array(['One thing was not combinable', 'And another'])
    end
  end

  context 'with a mix of errors and successful results' do
    let(:other_child1_id) { 'druid:bar' }
    let(:other_child2_id) { 'druid:baz' }
    let(:other_parent_id) { 'druid:foo' }
    let(:virtual_objects) do
      [
        { parent_id: parent_id, child_ids: [child1_id, child2_id] },
        { parent_id: other_parent_id, child_ids: [other_child1_id, other_child2_id] }
      ]
    end

    before do
      allow(ConstituentService).to receive(:new)
        .with(parent_druid: other_parent_id, event_factory: EventFactory).and_return(service)
      allow(service).to receive(:add).and_return(nil, parent_id => ['One thing was not combinable', 'And another'])
      described_class.perform_now(virtual_objects: virtual_objects,
                                  background_job_result: result)
    end

    it 'marks the job as processing' do
      expect(result).to have_received(:processing!).once
    end

    it 'invokes the constituent service to do the virtual object creation' do
      expect(service).to have_received(:add).with(child_druids: [child1_id, child2_id]).once
      expect(service).to have_received(:add).with(child_druids: [other_child1_id, other_child2_id]).once
    end

    it 'marks the job as complete' do
      expect(result).to be_complete
    end

    it 'has output with errors' do
      expect(result.output[:errors].first[parent_id]).to match_array(['One thing was not combinable', 'And another'])
    end
  end
end
