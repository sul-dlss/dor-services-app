# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::ContentMetadataNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(druid: 'druid:bb035tg0974', content_ng_xml: Nokogiri::XML(original_xml)) }
  let(:normalized_roundtripped_ng_xml) { described_class.normalize_roundtrip(content_ng_xml: Nokogiri::XML(original_xml)) }

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

    let(:expected_xml) do
      <<~XML
        <contentMetadata objectId="druid:bk689jd2364" type="file">
          <resource type="file">
            <file id="Decision.Record_6-30-03_signed.pdf" preserve="yes" publish="yes" shelve="yes" mimetype="application/pdf" size="102937">
              <checksum type="md5">50d5fc2730503a98bc2dda643064ae5b</checksum>
              <checksum type="sha1">df31b2f415d8e0806fa283db4e2c7fda690d1b02</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes the ids' do
      expect(normalized_ng_xml).to be_equivalent_to(expected_xml)
    end

    it 'removes the ids from roundtripped' do
      expect(normalized_roundtripped_ng_xml).to be_equivalent_to(expected_xml)
    end
  end

  context 'when normalizing resource objectids' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="druid:bb035tg0974" type="file">
          <resource objectId="druid:bb035tg0974" id="content" type="file" />
        </contentMetadata>
      XML
    end

    let(:expected_xml) do
      <<~XML
        <contentMetadata objectId="druid:bb035tg0974" type="file">
          <resource type="file" />
        </contentMetadata>
      XML
    end

    it 'removes resource objectids' do
      expect(normalized_ng_xml).to be_equivalent_to(expected_xml)
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

  context 'when normalizing reading order' do
    context 'when not a book' do
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="image" />
        XML
      end

      it 'does nothing' do
        expect(normalized_ng_xml).to be_equivalent_to(original_xml)
      end
    end

    context 'when reading order already exists' do
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="book">
            <bookData readingOrder="ltr"/>
          </contentMetadata>
        XML
      end

      it 'does nothing' do
        expect(normalized_ng_xml).to be_equivalent_to(original_xml)
      end
    end

    context 'when no resources' do
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="book" />
        XML
      end

      before do
        allow(AdministrativeTags).to receive(:content_type).and_return(['Book (ltr)'])
      end

      it 'does nothing' do
        expect(normalized_ng_xml).to be_equivalent_to(original_xml)
      end
    end

    context 'when reading missing' do
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="book">
            <resource sequence="1" type="page" />
          </contentMetadata>
        XML
      end

      before do
        allow(AdministrativeTags).to receive(:content_type).and_return(['Book (ltr)'])
      end

      it 'adds' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <contentMetadata objectId="druid:bb035tg0974" type="book">
              <bookData readingOrder="ltr"/>
              <resource type="page" />
            </contentMetadata>
          XML
        )
      end
    end

    context 'when normalizing format' do
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bk689jd2364" type="file">
            <resource type="page" sequence="268" id="page268">
              <file preserve="yes" mimetype="image/jp2" format="JPEG2000" size="92631" shelve="no" id="00000268.jp2" deliver="no">
                <imageData width="1310" height="2071"/>
                <checksum type="SHA-1">50d77a392ba30dcbbf4ada379e09ded02f9658f2</checksum>
                <checksum type="MD5">dcea2fd8ed01b2ef978093cf45ea3ce9</checksum>
              </file>
              <file preserve="yes" mimetype="text/html" format="HTML" size="19144" dataType="hocr" shelve="yes" id="00000268.html" deliver="no">
                <checksum type="SHA-1">335c75c2e2a13f024f73b0dd7dc5fc35fc47e7ce</checksum>
                <checksum type="MD5">42d8261046c449230a7c3809a246b353</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      it 'removes format' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <contentMetadata objectId="druid:bk689jd2364" type="file">
              <resource type="page">
                <file preserve="yes" mimetype="image/jp2" size="92631" shelve="no" id="00000268.jp2" publish="no">
                  <imageData width="1310" height="2071"/>
                  <checksum type="SHA-1">50d77a392ba30dcbbf4ada379e09ded02f9658f2</checksum>
                  <checksum type="MD5">dcea2fd8ed01b2ef978093cf45ea3ce9</checksum>
                </file>
                <file preserve="yes" mimetype="text/html" size="19144" dataType="hocr" shelve="yes" id="00000268.html" publish="no">
                  <checksum type="SHA-1">335c75c2e2a13f024f73b0dd7dc5fc35fc47e7ce</checksum>
                  <checksum type="MD5">42d8261046c449230a7c3809a246b353</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        )
      end
    end

    context 'when normalizing location' do
      let(:original_xml) do
        <<~XML
          <contentMetadata type="file" objectId="druid:tt395zz8686">
            <resource objectId="druid:tt395zz8686" id="content" type="file">
              <label>Using xSearch for Accelerating Research-Review of Deep Web Technologies Federated Search Service</label>
              <file preserve="yes" deliver="yes" size="4333001" mimetype="application/pdf" id="xSearch_Review_Charleston_Advisor.pdf" shelve="yes" publish="yes">
                <location type="url">https://stacks.stanford.edu/file/druid:tt395zz8686/xSearch_Review_Charleston_Advisor.pdf</location>
                <checksum type="md5">c22b3d0fd5569fc1039901bf22dad4f0</checksum>
                <checksum type="sha1">50b90a7ef7937b048db6f6d4b41637f59a2a57cf</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      it 'removes location' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
              <contentMetadata type="file" objectId="druid:tt395zz8686">
              <resource type="file">
                <label>Using xSearch for Accelerating Research-Review of Deep Web Technologies Federated Search Service</label>
                <file preserve="yes" size="4333001" mimetype="application/pdf" id="xSearch_Review_Charleston_Advisor.pdf" shelve="yes" publish="yes">
                  <checksum type="md5">c22b3d0fd5569fc1039901bf22dad4f0</checksum>
                  <checksum type="sha1">50b90a7ef7937b048db6f6d4b41637f59a2a57cf</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        )
      end
    end
  end

  context 'when normalizing attr mergedFromResource and mergedFromPid' do
    let(:original_xml) do
      <<~XML
          <contentMetadata type="image" objectId="druid:vv119cy9094">
            <resource type="image" sequence="2">
              <attr name="mergedFromResource">rh008rn6156_1</attr>
              <attr name="mergedFromPid">druid:rh008rn6156</attr>
              <attr name="representation">uncropped</attr>
              <label>Image 2</label>
              <file preserve="yes" shelve="no" publish="no" id="IMG_08673_2.JPG" mimetype="image/jpeg" size="141335">
                <checksum type="md5">53b3d300e4f03dd122c4eba604bf6750</checksum>
                <checksum type="sha1">f8cfabf0d7b60040b7c881f69612715a565efcb3</checksum>
                <imageData width="720" height="576"/>
              </file>
              <file id="IMG_08673_2.jp2" mimetype="image/jp2" size="78198" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">6e1deb86a3560b5dff0dfc2e37a00f53</checksum>
                <checksum type="sha1">bc8790cf29fd47e873ebf702f954d3ba8e242694</checksum>
                <imageData width="720" height="576"/>
              </file>
            </resource>
        </contentMetadata>
      XML
    end

    it 'removes attr' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
              <contentMetadata type="image" objectId="druid:vv119cy9094">
              <resource type="image">
                <label>Image 2</label>
                <file preserve="yes" shelve="no" publish="no" id="IMG_08673_2.JPG" mimetype="image/jpeg" size="141335">
                  <checksum type="md5">53b3d300e4f03dd122c4eba604bf6750</checksum>
                  <checksum type="sha1">f8cfabf0d7b60040b7c881f69612715a565efcb3</checksum>
                  <imageData width="720" height="576"/>
                </file>
                <file id="IMG_08673_2.jp2" mimetype="image/jp2" size="78198" preserve="no" publish="yes" shelve="yes">
                  <checksum type="md5">6e1deb86a3560b5dff0dfc2e37a00f53</checksum>
                  <checksum type="sha1">bc8790cf29fd47e873ebf702f954d3ba8e242694</checksum>
                  <imageData width="720" height="576"/>
                </file>
              </resource>
          </contentMetadata>
        XML
      )
    end
  end
end
