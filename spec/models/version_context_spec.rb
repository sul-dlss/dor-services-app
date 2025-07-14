# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionContext do
  let(:version_context) { create(:version_context) }

  it 'includes the context as a hash' do
    expect(version_context.values).to eq({ 'requireOCR' => true, 'requireTranscript' => true })
  end

  it 'validates the uniqueness of druid and version combination' do
    expect(described_class.new(druid: version_context.druid, version: version_context.version)).not_to be_valid
  end

  it 'validates the druid' do
    expect(described_class.new(druid: 'foo', version: '1')).not_to be_valid
  end
end
