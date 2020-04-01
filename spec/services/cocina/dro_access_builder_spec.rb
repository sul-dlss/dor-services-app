# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::DROAccessBuilder do
  subject(:access) { described_class.build(item) }

  let(:item) do
    Dor::Item.new
  end
  let(:rights_metadata_ds) { Dor::RightsMetadataDS.new.tap { |ds| ds.content = xml } }

  before do
    allow(item).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  context 'with useAndReproduction and no copyright' do
    # From https://argo.stanford.edu/view/druid:bb000kg4251
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction">Property rights reside with the repository. Literary rights reside with the creators of the documents or their heirs. To obtain permission to publish or reproduce, please contact the Public Services Librarian of the Dept. of Special Collections (http://library.stanford.edu/spc).</human>
          </use>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world',
                           download: 'world',
                           useAndReproductionStatement: 'Property rights reside with the repository. '\
                           'Literary rights reside with the creators of the documents or their heirs. ' \
                           'To obtain permission to publish or reproduce, please contact the Public ' \
                           'Services Librarian of the Dept. of Special Collections ' \
                           '(http://library.stanford.edu/spc).')
    end
  end

  describe 'with copyright' do
    # from https://argo.stanford.edu/view/druid:bb003dn0409
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <use>
            <human type="useAndReproduction">Official WTO documents are free for public use.</human>
            <human type="creativeCommons"/>
            <machine type="creativeCommons"/>
          </use>
          <copyright>
            <human>Copyright &#xA9; World Trade Organization</human>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world',
                           download: 'world',
                           copyright: 'Copyright © World Trade Organization',
                           useAndReproductionStatement: 'Official WTO documents are free for public use.')
    end
  end

  describe 'with copyright but no use statement (contrived example)' do
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
          <copyright>
            <human>Copyright &#xA9; DLSS</human>
          </copyright>
        </rightsMetadata>
      XML
    end

    it 'builds the hash' do
      expect(access).to eq(access: 'world',
                           download: 'world',
                           copyright: 'Copyright © DLSS')
    end
  end

  context 'with an embargo' do
    before do
      EmbargoService.create(item: item,
                            release_date: DateTime.parse('2029-02-28'),
                            access: 'world',
                            use_and_reproduction_statement: 'in public domain')
    end
    # from https://argo.stanford.edu/view/druid:bb003dn0409

    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <rightsMetadata>
          <access type="discover">
            <machine>
              <world/>
            </machine>
          </access>
          <access type="read">
            <machine>
              <world/>
            </machine>
          </access>
        </rightsMetadata>
      XML
    end

    it 'has embargo' do
      expect(access).to include(embargo: { access: 'world', releaseDate: '2029-02-28T00:00:00Z', useAndReproductionStatement: 'in public domain' })
    end
  end
end
