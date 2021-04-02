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
           <human type="creativeCommons">No Rights Reserved</human>
           <machine type="creativeCommons" uri="https://creativecommons.org/share-your-work/public-domain/cc0/">cc0</machine>
           <human type="openDataCommons"/>
           <machine type="openDataCommons" uri=""/>
         </use>
      XML
    end
  end
end
