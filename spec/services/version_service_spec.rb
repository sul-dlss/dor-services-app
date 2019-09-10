# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionService do
  let(:druid) { 'druid:ab12cd3456' }

  let(:obj) do
    Dor::Item.new(pid: druid)
  end

  let(:vmd_ds) { obj.datastreams['versionMetadata'] }
  let(:ev_ds) { obj.datastreams['events'] }

  before do
    allow(obj).to receive(:pid).and_return(druid)

    allow(obj.inner_object).to receive(:repository).and_return(double('frepo').as_null_object)
  end

  describe '.open' do
    subject(:open) { described_class.open(obj) }

    context 'when on the expected path' do
      before do
        allow(SdrClient).to receive(:current_version).and_return(1)
        allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
        allow(obj).to receive(:new_record?).and_return(false)
        allow(vmd_ds).to receive(:save)
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client,
                        create_workflow_by_name: true,
                        lifecycle: true,
                        active_lifecycle: nil)
      end

      it 'creates the versionMetadata datastream and starts a workflow' do
        expect(SdrClient).to receive(:current_version).and_return(1)
        expect(obj).to receive(:new_record?).and_return(false)
        expect(vmd_ds).to receive(:save)
        expect(vmd_ds.ng_xml.to_xml).to match(/Initial Version/)
        open
        expect(workflow_client).to have_received(:lifecycle).with('dor', druid, 'accessioned')
        expect(workflow_client).to have_received(:active_lifecycle).with('dor', druid, 'opened')
        expect(workflow_client).to have_received(:active_lifecycle).with('dor', druid, 'submitted')
        expect(workflow_client).to have_received(:create_workflow_by_name).with(obj.pid, 'versioningWF')
      end

      it 'includes options' do
        options = { significance: 'real_major', description: 'same as it ever was', opening_user_name: 'sunetid' }
        cur_vers = '2'
        allow(vmd_ds).to receive(:current_version).and_return(cur_vers)
        allow(obj).to receive(:save!)

        expect(ev_ds).to receive(:add_event).with('open', options[:opening_user_name], "Version #{cur_vers} opened")
        expect(vmd_ds).to receive(:update_current_version).with(description: options[:description], significance: options[:significance].to_sym)
        expect(obj).to receive(:save!)

        described_class.open(obj, **options)
      end

      it "doesn't include options" do
        expect(ev_ds).not_to receive(:add_event)
        expect(vmd_ds).not_to receive(:update_current_version)
        expect(obj).not_to receive(:save!)

        open
      end
    end

    context 'when a new version cannot be opened' do
      let(:instance) { described_class.new obj }

      before do
        allow(instance).to receive(:try_to_get_current_version).and_raise(Dor::Exception, 'Object net yet accessioned')
        allow(described_class).to receive(:new).and_return(instance)
      end

      it 'raises an exception' do
        expect { open }.to raise_error(Dor::Exception, 'Object net yet accessioned')
      end
    end

    context "when SDR's current version is greater than the current version" do
      it 'raises an exception' do
        expect(Dor::Config.workflow.client).to receive(:lifecycle).with('dor', druid, 'accessioned').and_return(true)
        expect(Dor::Config.workflow.client).to receive(:active_lifecycle).with('dor', druid, 'opened').and_return(nil)
        expect(Dor::Config.workflow.client).to receive(:active_lifecycle).with('dor', druid, 'submitted').and_return(nil)
        expect(SdrClient).to receive(:current_version).and_return(3)
        expect { open }.to raise_error(Dor::Exception, 'Cannot sync to a version greater than current: 1, requested 3')
      end
    end

    context "when sdr-services-app doesn't know about the object" do
      before do
        allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
        allow(SdrClient).to receive(:current_version).and_raise(Dor::Exception, 'SDR is not yet answering queries about this object')
      end

      let(:workflow_client) do
        instance_double(Dor::Workflow::Client,
                        lifecycle: true,
                        active_lifecycle: nil)
      end

      it 'raises an exception' do
        expect { open }.to raise_error(Dor::Exception, /SDR is not yet answering queries about this object/)
      end
    end
  end

  describe '.can_open?' do
    subject(:can_open?) { described_class.can_open?(obj) }

    before do
      allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
    end

    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      lifecycle: true,
                      active_lifecycle: nil)
    end

    context 'when a new version can be opened' do
      before do
        allow(SdrClient).to receive(:current_version).and_return(1)
      end

      it 'returns true' do
        expect(can_open?).to be true
        expect(workflow_client).to have_received(:lifecycle).with('dor', druid, 'accessioned')
        expect(workflow_client).to have_received(:active_lifecycle).with('dor', druid, 'opened')
        expect(workflow_client).to have_received(:active_lifecycle).with('dor', druid, 'submitted')
      end
    end

    context 'when the object has not been accessioned' do
      before do
        allow(workflow_client).to receive(:lifecycle).with('dor', druid, 'accessioned').and_return(false)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_client).to have_received(:lifecycle).with('dor', druid, 'accessioned')
      end
    end

    context 'when the object has already been opened' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with('dor', druid, 'opened').and_return(Time.new)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_client).to have_received(:active_lifecycle).with('dor', druid, 'opened')
      end
    end

    context 'when the object is still being accessioned' do
      before do
        allow(workflow_client).to receive(:active_lifecycle).with('dor', druid, 'submitted').and_return(Time.new)
      end

      it 'returns false' do
        expect(can_open?).to be false
        expect(workflow_client).to have_received(:active_lifecycle).with('dor', druid, 'submitted')
      end
    end

    context "when sdr-services-app doesn't know about the object" do
      before do
        allow(SdrClient).to receive(:current_version).and_raise(Dor::Exception)
      end

      it 'returns false' do
        expect(can_open?).to be false
      end
    end
  end

  describe '.close' do
    subject(:close) { described_class.close(obj) }

    context 'when significance, description and user_name are passed in' do
      before do
      end

      it 'sets tag, description and an event' do
        allow(vmd_ds).to receive(:pid).and_return('druid:ab123cd4567')
        allow(Dor::Config.workflow.client).to receive(:active_lifecycle).and_return(true, false)

        # Stub out calls to update and archive workflow
        allow(Dor::Config.workflow.client).to receive(:update_workflow_status)

        expect(Dor::Config.workflow.client).to receive(:close_version).with('dor', druid, true)

        allow(obj).to receive(:create_workflow)
        vmd_ds.increment_version

        expect(vmd_ds).to receive(:save)
        expect(ev_ds).to receive(:add_event).with('close', 'jcoyne', 'Version 2 closed')
        expect(obj).to receive(:save!)

        described_class.close obj, description: 'closing text', significance: 'major', user_name: 'jcoyne'

        expect(vmd_ds.to_xml).to be_equivalent_to <<~XML
          <versionMetadata objectId="druid:ab123cd4567">
            <version versionId="1" tag="1.0.0">
              <description>Initial Version</description>
            </version>
            <version versionId="2" tag="2.0.0">
              <description>closing text</description>
            </version>
          </versionMetadata>
        XML
      end
    end

    context 'when the object has not been opened for versioning' do
      it 'raises an exception' do
        expect(Dor::Config.workflow.client).to receive(:active_lifecycle).with('dor', druid, 'opened').and_return(nil)
        expect { close }.to raise_error(Dor::Exception, 'Trying to close version on an object not opened for versioning')
      end
    end

    context 'when the object already has an active instance of accesssionWF' do
      it 'raises an exception' do
        expect(Dor::Config.workflow.client).to receive(:active_lifecycle).with('dor', druid, 'opened').and_return(Time.new)
        expect(Dor::Config.workflow.client).to receive(:active_lifecycle).with('dor', druid, 'submitted').and_return(true)
        expect { close }.to raise_error(Dor::Exception, 'accessionWF already created for versioned object')
      end
    end

    context 'when the latest version does not have a tag and a description' do
      it 'raises an exception' do
        vmd_ds.increment_version
        expect { close }.to raise_error(Dor::Exception, 'latest version in versionMetadata requires tag and description before it can be closed')
      end
    end
  end
end
