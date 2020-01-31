# frozen_string_literal: true

namespace :dsa do
  desc 'Embargo release'
  task embargo_release: :environment do
    EmbargoReleaseService.release
  end
end
