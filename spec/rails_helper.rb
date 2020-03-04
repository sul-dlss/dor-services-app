# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'

require 'equivalent-xml/rspec_matchers'
require 'rspec/matchers'
require 'rspec/rails'
require 'support/foxml_helper'
require 'support/factory_bot'

# Add additional requires below this line. Rails is not loaded until this point!

require 'rack/test'
require 'webmock/rspec'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include AuthHelper
  config.use_transactional_fixtures = true

  config.before :suite do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end

TEST_WORKSPACE = (Settings.stacks.local_workspace_root = 'tmp/dor/workspace')

def clean_workspace
  FileUtils.rm_rf Dir.glob(TEST_WORKSPACE + '/*')
end

def setup_test_objects(druid, identityMetadata, rightsMetadata = '<xml/>')
  @dor_item = instance_double(Dor::Item)
  @identityMetadataXML = Dor::IdentityMetadataDS.new
  @rightsMetadataXML = Dor::RightsMetadataDS.new
  allow(@identityMetadataXML).to receive_messages(ng_xml: Nokogiri::XML(identityMetadata))
  allow(@rightsMetadataXML).to receive_messages(ng_xml: Nokogiri::XML(rightsMetadata))
  allow(@dor_item).to receive_messages(
    id: druid,
    datastreams: { 'identityMetadata' => @identityMetadataXML, 'rightsMetadata' => @rightsMetadataXML },
    identityMetadata: @identityMetadataXML, rightsMetadata: @rightsMetadataXML
  )
  @dor_item
end

def instantiate_fixture(druid, klass = ActiveFedora::Base)
  mask = File.join(fixture_dir, "*_#{druid.sub(/:/, '_')}.xml")
  fname = Dir[mask].first
  return nil if fname.nil?

  item_from_foxml(File.read(fname), klass)
end

def fixture_dir
  @fixture_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

def read_fixture(fname)
  File.read(File.join(fixture_dir, fname))
end

# Creates a `not_change` matcher
RSpec::Matchers.define_negated_matcher :not_change, :change
