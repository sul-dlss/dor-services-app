# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::ContentMetadataNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(content_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when normalizing resource ids' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="druid:bk689jd2364" type="file">
          <resource id="bk689jd2364_1" sequence="1" type="file">
            <file id="Decision.Record_6-30-03_signed.pdf" preserve="yes" publish="yes" shelve="yes" mimetype="application/pdf" size="102937">
              <checksum type="md5">50d5fc2730503a98bc2dda643064ae5b</checksum>
              <checksum type="sha1">df31b2f415d8e0806fa283db4e2c7fda690d1b02</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes the ids' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata objectId="druid:bk689jd2364" type="file">
            <resource sequence="1" type="file">
              <file id="Decision.Record_6-30-03_signed.pdf" preserve="yes" publish="yes" shelve="yes" mimetype="application/pdf" size="102937">
                <checksum type="md5">50d5fc2730503a98bc2dda643064ae5b</checksum>
                <checksum type="sha1">df31b2f415d8e0806fa283db4e2c7fda690d1b02</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end

  context 'when normalizing objectId' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="bk689jd2364" type="file" />
      XML
    end

    it 'prefixes with druid:' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata objectId="druid:bk689jd2364" type="file" />
        XML
      )
    end
  end
end
