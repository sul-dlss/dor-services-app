# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Load rubyconfig gem so that we have access to env-specific settings
require 'config'

Config.load_and_set_settings(Config.setting_files('config', 'production'))

# These define jobs that checkin with Honeybadger.
# If changing the schedule of one of these jobs, also update at https://app.honeybadger.io/projects/50568/check_ins
job_type :rake_hb, 'cd :path && :environment_variable=:environment bundle exec rake --silent ":task" :output && curl --silent https://api.honeybadger.io/v1/check_in/:check_in'

# Suppress warnings to avoid unnecessary cron emails.
env 'RUBYOPT', '-W0'

every :day, at: '2:16am' do
  set :check_in, Settings.honeybadger_checkins.embargo_release
  rake_hb 'dsa:embargo_release'
end

# Run this an on off minute to avoid Google Books every 15 minutes
every :day, at: '8:35pm' do
  set :check_in, Settings.honeybadger_checkins.missing_druids
  rake_hb 'missing_druids:unindexed_objects'
end
