require 'rails_helper'

RSpec.describe Dor::GoobiTag do
  it 'encodes a tag as XML' do
    goobi_tag = described_class.new(name: 'tag_name', value: 'tag value')
    expect(goobi_tag.to_xml).to eq('<tag name="tag_name" value="tag value"/>')
  end

  it 'encodes a tag as XML with special characters' do
    goobi_tag = described_class.new(name: 'tag_name > and odd characters', value: 'tag value & other things')
    expect(goobi_tag.to_xml).to eq('<tag name="tag_name &gt; and odd characters" value="tag value &amp; other things"/>')
  end
end
