# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStep do
  subject(:step) do
    create(
      :workflow_step,
      workflow: 'accessionWF',
      process: 'start-accession',
      lifecycle: 'submitted'
    )
  end

  let(:completed_step) { create(:workflow_step, :completed) }

  it { is_expected.to be_valid }

  context 'without required values' do
    subject { described_class.create }

    it { is_expected.not_to be_valid }
  end

  context 'without valid druid' do
    it 'is not valid if the druid is missing the prefix' do
      expect { step.druid = step.druid.delete('druid:') }.to change(step, :valid?).from(true).to(false)
    end

    it 'is not valid if the druid is a bogus value' do
      expect { step.druid = 'bogus' }.to change(step, :valid?).from(true).to(false)
    end
  end

  context 'without valid status' do
    it 'is not valid if the status is nil' do
      expect { step.status = nil }.to change(step, :valid?).from(true).to(false)
    end

    it 'is not valid if the status is a bogus value' do
      expect { step.status = 'bogus' }.to change(step, :valid?).from(true).to(false)
    end
  end

  context 'when step already exists for the same druid/workflow/version' do
    subject(:dupe_step) do
      described_class.new(
        druid: step.druid,
        workflow: step.workflow,
        process: step.process,
        version: step.version,
        status: 'completed'
      )
    end

    it 'includes an informative error message' do
      expect(dupe_step).not_to be_valid
      expect(dupe_step.errors.messages).to match(hash_including(process: ['has already been taken']))
    end
  end

  context 'with non-existent workflow name' do
    subject(:bogus_workflow) do
      described_class.new(
        druid: step.druid,
        workflow: 'bogusWF',
        process: step.process,
        version: step.version,
        status: step.status
      )
    end

    it 'does not create a new workflow step' do
      expect(bogus_workflow).not_to be_valid
      expect(bogus_workflow.errors.messages).to match(hash_including(workflow: ['is not valid']))
    end
  end

  context 'with nil workflow name' do
    subject(:bogus_workflow) do
      described_class.new(
        druid: step.druid,
        workflow: nil,
        process: step.process,
        version: step.version,
        status: step.status
      )
    end

    it 'does not create a new workflow step' do
      expect(bogus_workflow).not_to be_valid
      expect(bogus_workflow.errors.messages).to match(hash_including(workflow: ['can\'t be blank', 'is not valid']))
    end
  end

  context 'with non-existent process name' do
    subject(:bogus_process) do
      described_class.new(
        druid: step.druid,
        workflow: step.workflow,
        process: 'bogus-step',
        version: step.version,
        status: step.status
      )
    end

    it 'is not possible to create a new workflow step for a non-existent or missing process value' do
      expect(bogus_process).not_to be_valid
      expect(bogus_process.errors.messages).to match(hash_including(process: ['is not valid']))
    end
  end

  context 'with nil process name' do
    subject(:bogus_process) do
      described_class.new(
        druid: step.druid,
        workflow: step.workflow,
        process: nil,
        version: step.version,
        status: step.status
      )
    end

    it 'is not possible to create a new workflow step for a non-existent or missing process value' do
      expect(bogus_process).not_to be_valid
      expect(bogus_process.errors.messages).to match(hash_including(process: ['can\'t be blank', 'is not valid']))
    end
  end

  context 'with invalid version' do
    [nil, 'bogus', 4.3, ''].each do |invalid_version|
      it "is not valid if the version is #{invalid_version}" do
        expect { step.version = invalid_version }.to change(step, :valid?).from(true).to(false)
      end
    end
  end

  context 'with workflow context' do
    let(:step_with_context) { create(:workflow_step, :with_ocr_context) }

    it 'includes the context as json' do
      expect(step_with_context.context).to eq({ 'requireOCR' => true, 'requireTranscript' => true })
    end
  end

  context 'without workflow context' do
    it 'includes the context as nil' do
      expect(step.context).to be_nil
    end
  end

  describe '#completed?' do
    it 'indicates if the step is not completed' do
      expect(step).not_to be_completed
    end

    it 'indicates if the step is completed' do
      expect(completed_step).to be_completed
    end
  end

  describe '#save' do
    context 'when completed and not already completed' do
      it 'sets a value for completed_at' do
        expect(step.completed_at).to be_nil
        step.status = 'completed'
        step.save
        expect(step.completed_at.to_i).to eq(step.updated_at.to_i) # use .to_i to ignore millisecond comparison
      end
    end

    context 'when completed and already completed' do
      let(:completed_at) { completed_step.completed_at }

      it 'leaves completed_at untouched' do
        expect(completed_step.completed_at).to eq(completed_at)
        completed_step.active_version = true
        completed_step.save
        expect(completed_step.completed_at).to eq(completed_at)
      end
    end
  end

  describe '#milestone_date' do
    it 'returns created_at if completed_at is nil' do
      expect(step.completed_at).to be_nil
      expect(step.milestone_date).to eq step.created_at.to_time.iso8601
    end

    it 'sets completed_at date and returns it as the milestone_date' do
      expect(step.completed_at).to be_nil
      step.status = 'completed'
      step.save
      expect(step.completed_at).not_to be_nil
      expect(step.milestone_date).to eq step.completed_at.to_time.iso8601
    end
  end

  describe '#as_milestone' do
    subject(:parsed_xml) { Nokogiri::XML(builder.to_xml) }

    let!(:builder) do
      Nokogiri::XML::Builder.new do |xml|
        step.as_milestone(xml)
      end
    end

    it 'serializes a Workflow as a milestone' do
      expect(parsed_xml.at_xpath('//milestone')).to include ['date', //], ['version', /1/]
      expect(parsed_xml.at_xpath('//milestone').content).to eq 'submitted'
    end
  end

  describe '#attributes_for_process' do
    it 'includes the expected values' do
      expect(step.attributes_for_process).to include(
        version: 1,
        note: nil,
        lifecycle: 'submitted',
        laneId: 'default',
        elapsed: nil,
        attempts: 0,
        datetime: String,
        status: 'waiting',
        name: 'start-accession'
      )
    end
  end
end
