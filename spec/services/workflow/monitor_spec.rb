# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::Monitor do
  before do
    allow(Honeybadger).to receive(:notify)

    # On deck
    create(:workflow_step,
           druid: stale.druid,
           process: 'publish',
           version: 1,
           status: 'waiting',
           active_version: true)

    create(:workflow_step,
           druid: completed.druid,
           process: 'publish',
           version: 2,
           status: 'waiting',
           active_version: true)

    # Started
    create(:workflow_step,
           druid: stale_started.druid,
           process: 'publish',
           version: 1,
           status: 'waiting',
           active_version: true)
  end

  describe '.monitor' do
    let(:stale) do
      create(:workflow_step,
             process: 'start-accession',
             version: 1,
             status: 'queued',
             active_version: true,
             updated_at: 2.days.ago)
    end

    let(:completed) do
      create(:workflow_step,
             process: 'start-accession',
             version: 2,
             status: 'completed',
             active_version: true,
             updated_at: 1.day.ago)
    end

    let(:stale_started) do
      create(:workflow_step,
             process: 'start-accession',
             version: 3,
             status: 'started',
             active_version: true,
             updated_at: 2.days.ago)
    end

    it 'reports to Honeybadger' do
      described_class.monitor
      expect(Honeybadger).to have_received(:notify).exactly(2).times

      expect(Honeybadger).to have_received(:notify)
        .with('Workflow step(s) has been running for more than 48 hours. Perhaps there is a problem.',
              context: { steps: [{ druid: stale_started.druid, version: stale_started.version,
                                   workflow: stale_started.workflow, process: stale_started.process }] })

      expect(Honeybadger).to have_received(:notify)
        .with('Workflow step(s) have been queued for more than 24 hours. Perhaps there is a problem with the robots.',
              context: { steps: [{ druid: stale.druid, version: stale.version, workflow: stale.workflow,
                                   process: stale.process }] })
    end
  end
end
