# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::License do
  subject(:apply) { described_class.update(datastream, uri) }

  let(:datastream) do
    Dor::DefaultObjectRightsDS.new
  end

  context 'with cc0' do
    let(:uri) { 'https://creativecommons.org/share-your-work/public-domain/cc0/' }

    it 'writes the XML' do
      apply
      expect(datastream.ng_xml.xpath('//use')).to be_equivalent_to <<~XML
        <use>
           <human type="useAndReproduction"/>
           <license>https://creativecommons.org/share-your-work/public-domain/cc0/</license>
        </use>
      XML
    end
  end
end
