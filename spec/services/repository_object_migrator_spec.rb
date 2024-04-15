# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryObjectMigrator do
  let(:external_identifier) { generate(:unique_druid) }

  describe '.migrate' do
    before do
      allow(described_class).to receive(:new).and_return(fake_instance)
    end

    let(:fake_instance) { instance_double(described_class, migrate: nil) }

    it 'invokes #migrate on a new instance' do
      described_class.migrate(external_identifier:)
      expect(fake_instance).to have_received(:migrate).once
    end
  end

  describe '#migrate' do
    subject(:new_object) { migrator.migrate }

    before do
      allow(CocinaObjectStore).to receive(:ar_find).and_return(old_object)
      allow(migrator).to receive(:workflow_status).with(version_number: 1).and_return(fake_workflow_status)
      allow(migrator).to receive(:open_version?).with(version_number: 1).and_return(open_version)
    end

    let(:fake_workflow_status) do
      instance_double(Dor::Workflow::Client::Status, status_time:, display_simplified: workflow_display)
    end
    let(:migrator) { described_class.new(external_identifier:) }
    let(:old_object) do
      create(:ar_dro, :with_geographic, :with_object_versions,
             external_identifier:,
             isMemberOf: [generate(:unique_druid)])
    end
    let(:open_version) { true }
    let(:workflow_display) { 'Registered' }
    let(:status_time) { nil }

    it 'uses the CocinaObjectStore to find the old object' do
      new_object # do the migration
      expect(CocinaObjectStore).to have_received(:ar_find).once
    end

    it 'uses the external_identifier from the old object' do
      expect(new_object.external_identifier).to eq(old_object.external_identifier)
    end

    it 'uses the source_id from the old object' do
      expect(new_object.source_id).to eq(old_object.identification.fetch('sourceId'))
    end

    it 'uses the object_type from the old object' do
      expect(new_object.object_type).to eq('dro')
    end

    it 'uses the created_at from the old object' do
      # NOTE: The old AR models were created before Rails defaulted to
      # `precision: 6` for timestamp fields, so these values won't be purely
      # equivalent, but will vary by well less than thousandths of a millisecond.
      expect(new_object.created_at).to be_within(0.001.seconds).of(old_object.created_at)
    end

    it 'uses the updated_at from the old object' do
      # NOTE: The old AR models were created before Rails defaulted to
      # `precision: 6` for timestamp fields, so these values won't be purely
      # equivalent, but will vary by well less than thousandths of a millisecond.
      expect(new_object.updated_at).to be_within(0.001.seconds).of(old_object.updated_at)
    end

    it 'uses the lock from the old object' do
      expect(new_object.lock).to eq(old_object.lock)
    end

    context 'when object is a collection' do
      let(:old_object) do
        create(:ar_collection, :with_object_versions, external_identifier:)
      end

      it 'uses the object_type from the old object' do
        expect(new_object.object_type).to eq('collection')
      end

      it 'has a head version with the expected content_type' do
        expect(new_object.head_version.content_type).to eq('https://cocina.sul.stanford.edu/models/collection')
      end

      it 'has a head version with nil structural' do
        expect(new_object.head_version.structural).to be_nil
      end

      it 'has a head version with nil geographic' do
        expect(new_object.head_version.geographic).to be_nil
      end
    end

    context 'when object is an admin policy' do
      let(:old_object) do
        create(:ar_admin_policy, :with_object_versions, external_identifier:)
      end

      it 'uses the object_type from the old object' do
        expect(new_object.object_type).to eq('admin_policy')
      end

      it 'has a nil source_id' do
        expect(new_object.source_id).to be_nil
      end

      it 'has the expected content_type' do
        expect(new_object.head_version.content_type).to eq('https://cocina.sul.stanford.edu/models/admin_policy')
      end

      it 'has a nil access' do
        expect(new_object.head_version.access).to be_nil
      end

      it 'has a nil description' do
        expect(new_object.head_version.description).to be_nil
      end

      it 'has a nil structural' do
        expect(new_object.head_version.structural).to be_nil
      end

      it 'has a nil geographic' do
        expect(new_object.head_version.geographic).to be_nil
      end
    end

    context 'when old object has only one, unaccessioned version' do
      let(:old_object_version) { ObjectVersion.find_by(druid: external_identifier, version: 1) }

      it 'sets the object version as head_version' do
        expect(new_object.head_version).to eq(new_object.versions.first)
      end

      it 'sets the object version as opened_version' do
        expect(new_object.opened_version).to eq(new_object.versions.first)
      end

      it 'has no last_closed_version set' do
        expect(new_object.last_closed_version).to be_nil
      end

      it 'uses the created_at from the associated ObjectVersion instance' do
        expect(new_object.head_version.created_at).to be_within(0.001.seconds).of(old_object_version.created_at)
      end

      it 'uses the updated_at from the associated ObjectVersion instance' do
        expect(new_object.head_version.updated_at).to be_within(0.001.seconds).of(old_object_version.updated_at)
      end

      it 'uses the version description from the associated ObjectVersion instance' do
        expect(new_object.head_version.version_description).to eq(old_object_version.description)
      end

      it 'leaves the version closed_at attribute unset' do
        expect(new_object.head_version.closed_at).to be_nil
      end

      it 'uses the content_type from the old object' do
        expect(new_object.head_version.content_type).to eq(old_object.content_type)
      end

      it 'sets the cocina version on the object version' do
        expect(new_object.head_version.cocina_version).to eq(old_object.cocina_version)
      end

      it 'sets the label on the object version' do
        expect(new_object.head_version.label).to eq(old_object.label)
      end

      it 'sets the access on the object version' do
        expect(new_object.head_version.access).to eq(old_object.access)
      end

      it 'sets the administrative on the object version' do
        expect(new_object.head_version.administrative).to eq(old_object.administrative)
      end

      it 'sets the description on the object version' do
        expect(new_object.head_version.description).to eq(old_object.description)
      end

      it 'sets the identification on the object version' do
        expect(new_object.head_version.identification).to eq(old_object.identification)
      end

      it 'sets the structural on the object version' do
        expect(new_object.head_version.structural).to eq(old_object.structural)
      end

      it 'sets the geographic on the object version' do
        expect(new_object.head_version.geographic).to eq(old_object.geographic)
      end

      context 'when version has been accessioned' do
        let(:open_version) { false }
        let(:status_time) { 3.days.ago.to_s }
        let(:workflow_display) { 'Accessioned' }

        it 'sets the object version as last_closed_version' do
          expect(new_object.last_closed_version).to eq(new_object.versions.first)
        end

        it 'has no opened_version set' do
          expect(new_object.opened_version).to be_nil
        end

        it 'sets the version closed_at attribute to what the workflow client reports' do
          expect(new_object.last_closed_version.closed_at).to eq(status_time)
        end
      end
    end

    context 'when old object has multiple versions' do
      let(:latest_version) { 5 }
      let(:old_object) do
        create(:ar_dro, :with_geographic, :with_object_versions,
               version: latest_version,
               external_identifier:,
               isMemberOf: [generate(:unique_druid)])
      end

      before do
        allow(migrator).to receive(:workflow_status).with(version_number: 1).once.and_return(
          instance_double(Dor::Workflow::Client::Status, status_time: 10.days.ago.to_s, display_simplified: 'Accessioned')
        )
        allow(migrator).to receive(:workflow_status).with(version_number: 2).once.and_return(
          instance_double(Dor::Workflow::Client::Status, status_time: 8.days.ago.to_s, display_simplified: 'Accessioned')
        )
        allow(migrator).to receive(:workflow_status).with(version_number: 3).once.and_return(
          instance_double(Dor::Workflow::Client::Status, status_time: 6.days.ago.to_s, display_simplified: 'Accessioned')
        )
        allow(migrator).to receive(:workflow_status).with(version_number: 4).once.and_return(
          instance_double(Dor::Workflow::Client::Status, status_time: 4.days.ago.to_s, display_simplified: 'Accessioned')
        )
        allow(migrator).to receive(:workflow_status).with(version_number: 5).once.and_return(
          instance_double(Dor::Workflow::Client::Status, status_time: nil, display_simplified: 'Opened')
        )
        allow(migrator).to receive(:open_version?).with(version_number: 1).and_return(false)
        allow(migrator).to receive(:open_version?).with(version_number: 2).and_return(false)
        allow(migrator).to receive(:open_version?).with(version_number: 3).and_return(false)
        allow(migrator).to receive(:open_version?).with(version_number: 4).and_return(false)
        allow(migrator).to receive(:open_version?).with(version_number: 5).and_return(true)
      end

      it 'sets the latest version as head_version' do
        expect(new_object.head_version).to eq(new_object.versions.find_by(version: latest_version))
      end

      it 'sets the prior version as last_closed_version' do
        expect(new_object.last_closed_version).to eq(new_object.versions.find_by(version: latest_version - 1))
      end

      it 'sets the latest version as opened_version' do
        expect(new_object.opened_version).to eq(new_object.versions.find_by(version: latest_version))
      end

      %i[content_type cocina_version label access administrative description
         identification structural geographic].each do |cocina_field|
        it "sets the #{cocina_field} on the head version'" do
          expect(new_object.head_version.public_send(cocina_field)).to eq(old_object.public_send(cocina_field))
        end

        it "lacks the #{cocina_field} on prior versions such as the last closed version" do
          expect(new_object.last_closed_version.public_send(cocina_field)).to be_nil
        end
      end

      it 'has the same number of versions as the old object version' do
        expect(new_object.versions.count).to eq(old_object.version)
      end

      it 'has the same number of versions as the object version rows' do
        expect(new_object.versions.count).to eq(ObjectVersion.where(druid: external_identifier).count)
      end

      context 'when latest version has been accessioned' do
        before do
          allow(migrator).to receive(:workflow_status).with(version_number: 5).once.and_return(
            instance_double(Dor::Workflow::Client::Status, status_time: 2.days.ago.to_s, display_simplified: 'Accessioned')
          )
          allow(migrator).to receive(:open_version?).with(version_number: 5).and_return(false)
        end

        it 'sets the latest version as head_version' do
          expect(new_object.head_version).to eq(new_object.versions.find_by(version: latest_version))
        end

        it 'sets the latest version as last_closed_version' do
          expect(new_object.last_closed_version).to eq(new_object.versions.find_by(version: latest_version))
        end

        it 'unsets opened_version' do
          expect(new_object.opened_version).to be_nil
        end
      end
    end
  end
end
