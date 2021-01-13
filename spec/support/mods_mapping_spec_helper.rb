# frozen_string_literal: true

RSpec.shared_examples 'cocina to MODS' do |expected_xml|
  subject(:xml) { writer.to_xml }

  # writer object is declared in the context of calling examples

  let(:mods_attributes) do
    {
      'xmlns' => 'http://www.loc.gov/mods/v3',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'version' => '3.6',
      'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd'
    }
  end

  it 'builds the expected xml' do
    expect(xml).to be_equivalent_to <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{expected_xml}
      </mods>
    XML
  end
end
