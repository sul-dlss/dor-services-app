# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'bin/migrate-cocina' do # rubocop:disable RSpec/DescribeClass
  before(:context) do
    @apo = create(:repository_object, :admin_policy,
                  :with_repository_object_version, external_identifier: 'druid:hy787xj5878')
    @objects_to_migrate = [
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734'),
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:rd069rk9728')
    ]
    @objects_to_ignore = create_list(:repository_object, 2, :with_repository_object_version)
  end

  after(:context) do
    @objects_to_migrate.each(&:destroy!)
    @objects_to_ignore.each(&:destroy!)
    @apo.destroy!
  end

  let(:migrated_druids) { %w[druid:bc177tq6734 druid:rd069rk9728] }
  let(:objects_to_migrate) do
    @objects_to_migrate
  end

  let(:objects_to_ignore) do
    @objects_to_ignore
  end
  let(:ignored_druids) { objects_to_ignore.map(&:external_identifier) }

  let(:cmd_str) { 'bin/migrate-cocina "Migrators::Exemplar" --mode commit' }
  let(:cmd_result) do
    # avoid error '[__NSCFConstantString initialize] may have been in progress in another thread when fork() was called'
    # https://github.com/rails/rails/issues/38560
    env = { 'OBJC_DISABLE_INITIALIZE_FORK_SAFETY' => 'YES' }
    stdout_s, stderr_s, status = Open3.capture3(env, cmd_str, chdir: Rails.root.to_s)
    { stdout_s:, stderr_s:, status: }
  end

  it 'migrates exactly the objects it should' do
    expect(objects_to_migrate.first.head_version.label).not_to include('migrated')
    expect(objects_to_migrate.second.head_version.label).not_to include('migrated')
    expect(objects_to_ignore.first.head_version.label).not_to include('migrated')
    expect(objects_to_ignore.second.head_version.label).not_to include('migrated')

    puts "#{cmd_str} -- #{cmd_result}"
    expect(cmd_result[:status].exitstatus).to eq 0

    expect(RepositoryObject.find_by(external_identifier: migrated_druids[0]).head_version.label).to include('migrated')
    expect(RepositoryObject.find_by(external_identifier: migrated_druids[1]).head_version.label).to include('migrated')
    expect(
      RepositoryObject.find_by(external_identifier: ignored_druids[0]).head_version.label
    ).not_to include('migrated')
    expect(
      RepositoryObject.find_by(external_identifier: ignored_druids[1]).head_version.label
    ).not_to include('migrated')
  end
end
