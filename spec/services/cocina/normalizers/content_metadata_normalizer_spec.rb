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

  context 'when checksum type is uppercase' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="druid:bk689jd2364" type="file">
          <resource sequence="1" type="file">
            <file id="Decision.Record_6-30-03_signed.pdf" preserve="yes" publish="yes" shelve="yes" mimetype="application/pdf" size="102937">
              <checksum type="MD5">50d5fc2730503a98bc2dda643064ae5b</checksum>
              <checksum type="SHA1">df31b2f415d8e0806fa283db4e2c7fda690d1b02</checksum>
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

    it 'normalizes the checksum type to be lowercase' do
      expect(normalized_ng_xml).to be_equivalent_to(expected_xml)
    end
  end

  context 'when normalizing blank file directives' do
    # adapted from ft113wv9260 and ns538tk9778
    let(:original_xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:ft113wv9260">
          <resource id="ft113wv9260_1" type="file" objectId="druid:ft113wv9260">
            <file mimetype="image/tiff" preserve="" format="" size="456" shelve="" publish="no" id="ft113wv9260_00_0001.tif">
              <imageData width="4865" height="4933"/>
            </file>
            <file mimetype="image/tiff" preserve="yes" format="" size="123" shelve="yes" publish="" id="ft113wv9260_00_0002.tif">
              <imageData width="4865" height="4933"/>
          </file>
        </contentMetadata>
      XML
    end

    let(:expected_xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:ft113wv9260">
          <resource type="file">
            <file mimetype="image/tiff" preserve="no" size="456" shelve="no" publish="no" id="ft113wv9260_00_0001.tif">
              <imageData width="4865" height="4933"/>
            </file>
            <file mimetype="image/tiff" preserve="yes" size="123" shelve="yes" publish="no" id="ft113wv9260_00_0002.tif">
              <imageData width="4865" height="4933"/>
          </file>
        </contentMetadata>
      XML
    end

    it 'normalizes blank file directive attributes to no' do
      expect(normalized_ng_xml).to be_equivalent_to(expected_xml)
    end
  end

  context 'when normalizing labels' do
    # adapted from dm559qb5551 and fm402pc0937
    let(:original_xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:dm559qb5551">
          <resource id="dm559qb5551_3" type="permissions" objectId="druid:gc571ym3095">
            <attr name="label"/>
            <file id="OSA_Copyright_Statement.pdf" mimetype="application/pdf" size="128546" shelve="yes" publish="no" preserve="yes">
              <checksum type="md5">6b7b69c16a839fbb17e94c7cc5ec1467</checksum>
              <checksum type="sha1">0ebbc2d45e1b03df31d57accd8e442f2a8188b5a</checksum>
            </file>
          </resource>
          <resource id="dm559qb5551_4" type="permissions" objectId="druid:rw602tg5136">
            <attr name="label">Some cool label</attr>
            <file id="copyxfer.pdf" mimetype="application/pdf" size="57053" shelve="yes" publish="no" preserve="yes">
              <checksum type="md5">036df64941635bcfa525fe3faf86d84f</checksum>
              <checksum type="sha1">87fc2454991de4f60f26c1f6fa4b51b4e7c913f3</checksum>
            </file>
          </resource>
          <resource id="http://cocina.sul.stanford.edu/fileSet/18dabbd3-16fb-42be-9833-5da5401129a1" sequence="1" type="file">
            <label/>
            <file id="2021 March Off Highway Vehicles.pdf" mimetype="application/pdf" size="75211" publish="yes" shelve="yes" preserve="yes">
              <checksum type="sha1">f715cfa0f2a2cdd0fc14aa73a3e75326babe9ec4</checksum>
              <checksum type="md5">f3118304673f2135e3c37a6a233034b7</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    let(:expected_xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:dm559qb5551">
          <resource type="permissions">
            <file id="OSA_Copyright_Statement.pdf" mimetype="application/pdf" size="128546" shelve="yes" publish="no" preserve="yes">
              <checksum type="md5">6b7b69c16a839fbb17e94c7cc5ec1467</checksum>
              <checksum type="sha1">0ebbc2d45e1b03df31d57accd8e442f2a8188b5a</checksum>
            </file>
          </resource>
          <resource type="permissions">
            <label>Some cool label</label>
            <file id="copyxfer.pdf" mimetype="application/pdf" size="57053" shelve="yes" publish="no" preserve="yes">
              <checksum type="md5">036df64941635bcfa525fe3faf86d84f</checksum>
              <checksum type="sha1">87fc2454991de4f60f26c1f6fa4b51b4e7c913f3</checksum>
            </file>
          </resource>
          <resource type="file">
            <file id="2021 March Off Highway Vehicles.pdf" mimetype="application/pdf" size="75211" publish="yes" shelve="yes" preserve="yes">
              <checksum type="sha1">f715cfa0f2a2cdd0fc14aa73a3e75326babe9ec4</checksum>
              <checksum type="md5">f3118304673f2135e3c37a6a233034b7</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes empty <label /> and <attr name="label"> nodes' do
      expect(normalized_ng_xml).to be_equivalent_to(expected_xml)
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

  context 'when normalizing objectId with no type' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="bk689jd2364" />
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

  context 'when normalizing missing objectId' do
    let(:original_xml) do
      <<~XML
        <contentMetadata type="image" />
      XML
    end

    it 'adds druid as objectId' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="image" />
        XML
      )
    end
  end

  context 'when normalizing objectId without druid prefix' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="bb035tg0974" type="image" />
      XML
    end

    it 'adds druid prefix to objectId' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="image" />
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

      it 'does not add resources but adds bookData' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <contentMetadata objectId="druid:bb035tg0974" type="book">
              <bookData readingOrder="ltr"/>
            </contentMetadata>
          XML
        )
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

    context 'when reading missing and book right-to-left' do
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bb035tg0974" type="book">
            <resource sequence="1" type="page" />
          </contentMetadata>
        XML
      end

      before do
        allow(AdministrativeTags).to receive(:content_type).and_return(['Book (rtl)'])
      end

      it 'adds a "rtl" reading order' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <contentMetadata objectId="druid:bb035tg0974" type="book">
              <bookData readingOrder="rtl"/>
              <resource type="page" />
            </contentMetadata>
          XML
        )
      end
    end

    context 'when normalizing imageData' do
      # adapted from druid:bb101rd7954
      let(:original_xml) do
        <<~XML
          <contentMetadata objectId="druid:bb101rd7954" type="image">
            <resource type="image">
              <label>Image 1</label>
              <file id="Thumbs.db" mimetype="image/vnd.fpx" size="17408" preserve="yes" publish="no" shelve="no">
                <checksum type="MD5">99c8d3026749b6103f20c911ea102339</checksum>
                <checksum type="SHA1">f73a49b173c741b540170a4f3aa64b87988d4db7</checksum>
                <imageData width="" height="" size="500"/>
              </file>
            </resource>
            <resource type="image">
              <label>Image 2</label>
              <file id="Thumbs2.db" mimetype="image/vnd.fpx" size="17408" preserve="yes" publish="no" shelve="no">
                <checksum type="MD5">99c8d3026749b6103f20c911ea102339</checksum>
                <checksum type="SHA1">f73a49b173c741b540170a4f3aa64b87988d4db7</checksum>
                <imageData width="" height=""/>
              </file>
            </resource>
            <resource type="image">
              <label>Image 3</label>
              <file id="Thumbs3.db" mimetype="image/vnd.fpx" size="17408" preserve="yes" publish="no" shelve="no">
                <checksum type="MD5">99c8d3026749b6103f20c911ea102339</checksum>
                <checksum type="SHA1">f73a49b173c741b540170a4f3aa64b87988d4db7</checksum>
                <imageData/>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      it 'removes blank width and height attributes and blank imageData nodes' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <contentMetadata objectId="druid:bb101rd7954" type="image">
              <resource type="image">
                <label>Image 1</label>
                <file id="Thumbs.db" mimetype="image/vnd.fpx" size="17408" preserve="yes" publish="no" shelve="no">
                  <checksum type="md5">99c8d3026749b6103f20c911ea102339</checksum>
                  <checksum type="sha1">f73a49b173c741b540170a4f3aa64b87988d4db7</checksum>
                  <imageData size="500"/>
                </file>
              </resource>
              <resource type="image">
                <label>Image 2</label>
                <file id="Thumbs2.db" mimetype="image/vnd.fpx" size="17408" preserve="yes" publish="no" shelve="no">
                  <checksum type="md5">99c8d3026749b6103f20c911ea102339</checksum>
                  <checksum type="sha1">f73a49b173c741b540170a4f3aa64b87988d4db7</checksum>
                </file>
              </resource>
              <resource type="image">
                <label>Image 3</label>
                <file id="Thumbs3.db" mimetype="image/vnd.fpx" size="17408" preserve="yes" publish="no" shelve="no">
                  <checksum type="md5">99c8d3026749b6103f20c911ea102339</checksum>
                  <checksum type="sha1">f73a49b173c741b540170a4f3aa64b87988d4db7</checksum>
                </file>
              </resource>
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
                  <checksum type="sha-1">50d77a392ba30dcbbf4ada379e09ded02f9658f2</checksum>
                  <checksum type="md5">dcea2fd8ed01b2ef978093cf45ea3ce9</checksum>
                </file>
                <file preserve="yes" mimetype="text/html" size="19144" shelve="yes" id="00000268.html" publish="no">
                  <checksum type="sha-1">335c75c2e2a13f024f73b0dd7dc5fc35fc47e7ce</checksum>
                  <checksum type="md5">42d8261046c449230a7c3809a246b353</checksum>
                </file>
              </resource>
            </contentMetadata>
          XML
        )
      end
    end

    context 'when normalizing type="label" or name="label" attributes' do
      # adapted/modified from druid:bf016hc1150
      let(:original_xml) do
        <<~XML
            <contentMetadata type="file" objectId="druid:bf016hc1150">
            <resource id="bf016hc1150_1" type="main-original">
              <attr name="label">Body of dissertation (as submitted)</attr>
              <file id="Jiajing Wang_Dissertation_final.pdf" mimetype="application/pdf" size="10063288" shelve="yes" publish="no" preserve="yes">
                <checksum type="MD5">4730200a3f0e2e59a4b5222b24c56479</checksum>
                <checksum type="SHA1">1da942c37bf02c83a50840607e5d537981a685ca</checksum>
              </file>
            </resource>
            <resource id="bf016hc1150_2" type="main-augmented" objectId="druid:hn674mz7318">
              <attr type="label">Body of dissertation</attr>
              <file id="Jiajing Wang_Dissertation_final-augmented.pdf" mimetype="application/pdf" size="8669074" shelve="yes" publish="yes" preserve="yes">
                <checksum type="MD5">59447a86931f3663f5c129ffb2326808</checksum>
                <checksum type="SHA1">ff3b3c6ff560927890fc6258d5f7cb5073358624</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      it 'converts to label nodes' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <contentMetadata type="file" objectId="druid:bf016hc1150">
              <resource type="main-original">
                <label>Body of dissertation (as submitted)</label>
                <file id="Jiajing Wang_Dissertation_final.pdf" mimetype="application/pdf" size="10063288" shelve="yes" publish="no" preserve="yes">
                  <checksum type="md5">4730200a3f0e2e59a4b5222b24c56479</checksum>
                  <checksum type="sha1">1da942c37bf02c83a50840607e5d537981a685ca</checksum>
                </file>
              </resource>
              <resource type="main-augmented">
                <label>Body of dissertation</label>
                <file id="Jiajing Wang_Dissertation_final-augmented.pdf" mimetype="application/pdf" size="8669074" shelve="yes" publish="yes" preserve="yes">
                  <checksum type="md5">59447a86931f3663f5c129ffb2326808</checksum>
                  <checksum type="sha1">ff3b3c6ff560927890fc6258d5f7cb5073358624</checksum>
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
                <checksum type="MD5">c22b3d0fd5569fc1039901bf22dad4f0</checksum>
                <checksum type="SHA1">50b90a7ef7937b048db6f6d4b41637f59a2a57cf</checksum>
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
                <checksum type="MD5">53b3d300e4f03dd122c4eba604bf6750</checksum>
                <checksum type="SHA1">f8cfabf0d7b60040b7c881f69612715a565efcb3</checksum>
                <imageData width="720" height="576"/>
              </file>
              <file id="IMG_08673_2.jp2" mimetype="image/jp2" size="78198" preserve="no" publish="yes" shelve="yes">
                <checksum type="MD5">6e1deb86a3560b5dff0dfc2e37a00f53</checksum>
                <checksum type="SHA1">bc8790cf29fd47e873ebf702f954d3ba8e242694</checksum>
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

  context 'when normalizing resource nodes with data attributes' do
    # Adapted from zn580kw6428
    let(:original_xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:zn580kw6428">
          <resource data="content">
            <label>Experimental Evidence on the Disposition Effect</label>
            <file preserve="yes" shelve="yes" deliver="yes" size="919405" mimetype="application/pdf" id="v212299_pdf.pdf">
              <checksum type="MD5">174a44a8406b14949de14853612e4eb6</checksum>
              <checksum type="SHA1">258881e0f2293b90779cbc35e7f463882cc2bbf3</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes data attributes' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata type="file" objectId="druid:zn580kw6428">
            <resource>
              <label>Experimental Evidence on the Disposition Effect</label>
              <file preserve="yes" shelve="yes" publish="yes" size="919405" mimetype="application/pdf" id="v212299_pdf.pdf">
                <checksum type="md5">174a44a8406b14949de14853612e4eb6</checksum>
                <checksum type="sha1">258881e0f2293b90779cbc35e7f463882cc2bbf3</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end

  context 'when normalizing file nodes with dataType' do
    # Adapted from bb157dt2402
    let(:original_xml) do
      <<~XML
        <contentMetadata type="file" id="druid:bb035tg0974">
          <resource type="file">
            <file dataType="ARC" publish="no" shelve="yes" preserve="yes" id="CDL-20140924032424-00000-grebe.ucop.edu-00525747.arc.gz" size="14679718" mimetype="application/octet-stream">
              <checksum type="MD5">4cd0b913acd68cec050ab48b8f38c648</checksum>
              <checksum type="SHA1">bd758a1b039385638bfd6770d8c838ee4628eb86</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes the dataType attribute' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata type="file" objectId="druid:bb035tg0974">
            <resource type="file">
              <file publish="no" shelve="yes" preserve="yes" id="CDL-20140924032424-00000-grebe.ucop.edu-00525747.arc.gz" size="14679718" mimetype="application/octet-stream">
                <checksum type="md5">4cd0b913acd68cec050ab48b8f38c648</checksum>
                <checksum type="sha1">bd758a1b039385638bfd6770d8c838ee4628eb86</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end

  context 'when normalizing resource nodes with geoData' do
    # Adapted from cc377hs8114
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="cc377hs8114" type="geo">
          <resource id="cc377hs8114_1" sequence="1" type="object">
            <label>Data</label>
            <file preserve="yes" shelve="yes" publish="yes" id="data.zip" mimetype="application/zip" size="1216894" role="master">
              <geoData>
                <rdf:Description xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" rdf:about="http://purl.stanford.edu/cc377hs8114">
                  <dc:format xmlns:dc="http://purl.org/dc/elements/1.1/">application/x-esri-shapefile; format=Shapefile</dc:format>
                  <dc:type xmlns:dc="http://purl.org/dc/elements/1.1/">Dataset#LineString</dc:type>
                  <gml:boundedBy xmlns:gml="http://www.opengis.net/gml/3.2/">
                    <gml:Envelope gml:srsName="EPSG:4326">
                      <gml:lowerCorner>2.591614 4.547012</gml:lowerCorner>
                      <gml:upperCorner>13.628449 13.74575</gml:upperCorner>
                    </gml:Envelope>
                  </gml:boundedBy>
                  <dc:coverage xmlns:dc="http://purl.org/dc/elements/1.1/" rdf:resource="" dc:language="eng" dc:title="Nigeria"/>
                </rdf:Description>
              </geoData>
              <checksum type="SHA1">ae052966c362af7bcfec55a9ac2f2c4fdef21738</checksum>
              <checksum type="MD5">3e620e897533e7aee47a8b2f3dec7523</checksum>
            </file>
            <file preserve="no" shelve="yes" publish="yes" id="data_EPSG_4326.zip" mimetype="application/zip" size="1216232" role="derivative">
              <geoData srsName="EPSG:4326"/>
              <checksum type="SHA1">ea57ad73eab8b51f848ef53be73a2f9e6a63b2ca</checksum>
              <checksum type="MD5">6917a0345c5fc5d24c213994fcaadd44</checksum>
            </file>
          </resource>
          <resource id="cc377hs8114_2" sequence="2" type="preview">
            <label>Preview</label>
            <file preserve="yes" shelve="yes" publish="yes" id="preview.jpg" mimetype="image/jpeg" size="5954" role="master">
              <checksum type="SHA1">69054c3a2f650fcc70e30f5cf5d96372b715b34c</checksum>
              <checksum type="MD5">e2df985a2be01d7e685d3c485ac76873</checksum>
              <imageData width="200" height="133"/>
              </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes the geoData nodes' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata objectId="druid:cc377hs8114" type="geo">
            <resource type="object">
              <label>Data</label>
              <file preserve="yes" shelve="yes" publish="yes" id="data.zip" mimetype="application/zip" size="1216894" role="master">
                <checksum type="sha1">ae052966c362af7bcfec55a9ac2f2c4fdef21738</checksum>
                <checksum type="md5">3e620e897533e7aee47a8b2f3dec7523</checksum>
              </file>
              <file preserve="no" shelve="yes" publish="yes" id="data_EPSG_4326.zip" mimetype="application/zip" size="1216232" role="derivative">
                <checksum type="sha1">ea57ad73eab8b51f848ef53be73a2f9e6a63b2ca</checksum>
                <checksum type="md5">6917a0345c5fc5d24c213994fcaadd44</checksum>
              </file>
            </resource>
            <resource type="preview">
              <label>Preview</label>
              <file preserve="yes" shelve="yes" publish="yes" id="preview.jpg" mimetype="image/jpeg" size="5954" role="master">
                <checksum type="sha1">69054c3a2f650fcc70e30f5cf5d96372b715b34c</checksum>
                <checksum type="md5">e2df985a2be01d7e685d3c485ac76873</checksum>
                <imageData width="200" height="133"/>
                </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end

  context 'when normalizing empty xml contentMetadata' do
    # Adapted from bb423sd6663
    let(:original_xml) do
      <<~XML
        <xml type="file"/>
      XML
    end

    it 'replaces xml node with contentMetadata node' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata type="file" objectId="druid:bb035tg0974"/>
        XML
      )
    end
  end

  context 'when normalizing contentMetadata node' do
    let(:original_xml) do
      <<~XML
        <contentMetadata type="webarchive-seed" id="druid:bb035tg0974">
          <resource type="image" sequence="1" id="bb035tg0974_1">
            <file preserve="no" publish="yes" shelve="yes" mimetype="image/jp2" id="thumbnail.jp2" size="20199">
              <checksum type="MD5">7a2e7d50f03917674f8014cacd77cc26</checksum>
              <checksum type="SHA1">9db56401e6c2c2515c9d7a75b8316ca1d5425709</checksum>
              <imageData width="400" height="267"/>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes id in root element' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata type="webarchive-seed" objectId="druid:bb035tg0974">
            <resource type="image">
              <file preserve="no" publish="yes" shelve="yes" mimetype="image/jp2" id="thumbnail.jp2" size="20199">
                <checksum type="md5">7a2e7d50f03917674f8014cacd77cc26</checksum>
                <checksum type="sha1">9db56401e6c2c2515c9d7a75b8316ca1d5425709</checksum>
                <imageData width="400" height="267"/>
              </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end

  context 'when normalizing contentMetadata node with stacks' do
    let(:original_xml) do
      <<~XML
        <contentMetadata type="file" stacks="/web-archiving-stacks/data/collections/mm553tf6423" id="druid:bb035tg0974">
          <resource type="file">
            <file dataType="ARC" publish="no" shelve="yes" preserve="yes" id="CDL-20140226165709-00000-tanager.ucop.edu-00460137.arc.gz" size="50674265" mimetype="application/octet-stream">
              <checksum type="MD5">fec654ee17994c1ea3807fd7a6428321</checksum>
              <checksum type="SHA1">835753729f41968bc9e45c6cd1c1156fc6673812</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes stacks from root element' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata type="file" objectId="druid:bb035tg0974">
            <resource type="file">
              <file publish="no" shelve="yes" preserve="yes" id="CDL-20140226165709-00000-tanager.ucop.edu-00460137.arc.gz" size="50674265" mimetype="application/octet-stream">
                <checksum type="md5">fec654ee17994c1ea3807fd7a6428321</checksum>
                <checksum type="sha1">835753729f41968bc9e45c6cd1c1156fc6673812</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end

  context 'when normalizing files with provider_checksum' do
    let(:original_xml) do
      <<~XML
        <contentMetadata objectId="druid:bw260mc4853" type="image">
          <resource type="image">
            <label>Item 1</label>
            <file publish="no" shelve="no" preserve="yes" id="00008460_0001.tif" mimetype="image/tiff" size="502704556">
              <provider_checksum type="md5">71d813393ab0699fa58c26b9490a159e</provider_checksum>
              <checksum type="md5">71d813393ab0699fa58c26b9490a159e</checksum>
              <checksum type="sha1">efe7d6b501be9a5503817d19a3ec9072c9331cba</checksum>
              <imageData width="14785" height="11322"/>
            </file>
            <file id="00008460_0001.jp2" mimetype="image/jp2" size="31529801" preserve="no" publish="yes" shelve="yes">
              <checksum type="md5">ad6ddf7db816bcb1579fae80351a092d</checksum>
              <checksum type="sha1">3bbab77d76bcc261d1d2ef0765d75fe5919d84e8</checksum>
              <imageData width="14785" height="11322"/>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'removes provider_checksum' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <contentMetadata objectId="druid:bw260mc4853" type="image">
            <resource type="image">
              <label>Item 1</label>
              <file publish="no" shelve="no" preserve="yes" id="00008460_0001.tif" mimetype="image/tiff" size="502704556">
                <checksum type="md5">71d813393ab0699fa58c26b9490a159e</checksum>
                <checksum type="sha1">efe7d6b501be9a5503817d19a3ec9072c9331cba</checksum>
                <imageData width="14785" height="11322"/>
              </file>
              <file id="00008460_0001.jp2" mimetype="image/jp2" size="31529801" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">ad6ddf7db816bcb1579fae80351a092d</checksum>
                <checksum type="sha1">3bbab77d76bcc261d1d2ef0765d75fe5919d84e8</checksum>
                <imageData width="14785" height="11322"/>
              </file>
            </resource>
          </contentMetadata>
        XML
      )
    end
  end
end
