# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MigrationJob do
  let(:background_job_result) { create(:background_job_result) }
  let(:migrator_class) { Migrators::Exemplar }
  let(:batch_descriptor) { [0, 2] }
  let(:mode) { :dryrun }
  let(:druid1) { 'druid:mk420bs7601' }
  let(:druid2) { 'druid:mk420bs7602' }
  let(:druids_slice) { [druid1, druid2] }
  let(:obj1) { instance_double(RepositoryObject, id: 1, external_identifier: druid1) }
  let(:obj2) { instance_double(RepositoryObject, id: 2, external_identifier: druid2) }
  let(:error) { StandardError.new('something went wrong') }

  before do
    allow(Migrators::MigrationRunner).to receive(:druids_for_batch)
      .with(migrator_class:, batch_descriptor:)
      .and_return(druids_slice)

    allow(Migrators::MigrationRunner).to receive(:migrate_druid_list)
      .and_return([
                    { obj: obj1, status: 'SUCCESS' },
                    { obj: obj2, status: 'ERROR', exception: error }
                  ])
  end

  it 'performs the job' do
    expect do
      described_class.perform_now(migrator_class:, batch_descriptor:, mode:,
                                  background_job_result:)
    end.to change(background_job_result, :status).from('pending').to('complete')
    expect(background_job_result.output).to eq([
                                                 [1, druid1, 'SUCCESS'],
                                                 [2, druid2, 'ERROR', 'something went wrong']
                                               ])
    expect(Migrators::MigrationRunner).to have_received(:migrate_druid_list)
  end
end
