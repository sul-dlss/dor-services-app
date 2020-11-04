# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Mapper do
  subject(:cocina_model) { described_class.build(item) }

  context 'when item is a Dor::Item' do
    let(:item) do
      Dor::Item.new(pid: 'druid:mx000xm0000',
                    source_id: source_id,
                    label: 'test object',
                    admin_policy_object_id: 'druid:sc012gz0974')
    end

    let(:type) { 'Process : Content Type : 3D' }
    let(:content_type) { '3d' }
    let(:agreement) { 'druid:666' }
    let(:source_id) { 'whaever:8888' }

    before do
      allow(item).to receive(:collection_ids).and_return([])
      item.identityMetadata.agreementId = [agreement]
      item.descMetadata.title_info.main_title = 'Hello'

      # We can swap these two lines after https://github.com/sul-dlss/dor-services/pull/706
      # item.contentMetadata.contentType = [content_type]
      allow(item.contentMetadata).to receive(:contentType).and_return([content_type])

      create(:administrative_tag, druid: item.pid, tag_label: create(:tag_label, tag: 'Project : Google Books'))
      create(:administrative_tag, druid: item.pid, tag_label: create(:tag_label, tag: type))
    end

    context 'when item has a manuscript tag' do
      let(:type) { 'Process : Content Type : Manuscript (ltr)' }
      let(:content_type) { 'image' }

      it 'builds the object with type manuscript' do
        expect(cocina_model).to be_kind_of Cocina::Models::DRO
        expect(cocina_model.type).to eq Cocina::Models::Vocab.manuscript
      end
    end

    context 'when item has a book tag' do
      let(:content_type) { 'book' }

      before do
        allow(AdministrativeTags).to receive(:content_type).with(pid: item.id).and_return(['Book (rtl)'])
      end

      it 'builds the object with type book' do
        expect(cocina_model).to be_kind_of Cocina::Models::DRO
        expect(cocina_model.type).to eq Cocina::Models::Vocab.book
      end
    end

    context 'when item has a 3d content_type' do
      let(:content_type) { '3d' }

      it 'builds the object with type three_dimensional' do
        expect(cocina_model).to be_kind_of Cocina::Models::DRO
        expect(cocina_model.type).to eq Cocina::Models::Vocab.three_dimensional
      end
    end

    context 'when item has an image content_type' do
      let(:type) { 'Process : Content Type : Image' }
      let(:content_type) { 'image' }

      let(:content_metadata_ds) { Dor::ContentMetadataDS.from_xml(xml) }
      let(:xml) do
        <<~XML
          <contentMetadata objectId="bb000zn0114" type="image">
            <resource id="bb000zn0114_1" sequence="1" type="image">
              <label>Image 1</label>
              <file id="PC0062_2008-194_Q03_02_007.jpg" preserve="yes" publish="no" shelve="no" mimetype="image/jpeg" size="1480110">
                <checksum type="md5">8e656c63ea1ad476e515518a46824fac</checksum>
                <checksum type="sha1">0cd3613c7dda558433ad955f0cf4f2730e3ec958</checksum>
                <imageData width="2548" height="1696"/>
              </file>
              <file id="PC0062_2008-194_Q03_02_007.jp2" mimetype="image/jp2" size="819813" preserve="no" publish="yes" shelve="yes">
                <checksum type="md5">1f8d562f4f1fd87946a437176bb8e564</checksum>
                <checksum type="sha1">3206db5137c0820ede261488e08f4d4815d16078</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end
      let(:fileSet1) { cocina_model.structural.contains.first }

      before do
        allow(content_metadata_ds).to receive(:new?).and_return(false)
        allow(item).to receive(:contentMetadata).and_return(content_metadata_ds)
      end

      it 'builds the object with type image' do
        expect(cocina_model).to be_kind_of Cocina::Models::DRO
        expect(cocina_model.type).to eq Cocina::Models::Vocab.image
        expect(cocina_model.structural.contains.first).to be_file_set
        expect(fileSet1.label).to eq 'Image 1'
      end

      it 'files with imageData have presentation attribute with height and width' do
        file1 = fileSet1.structural.contains.first
        expect(file1.presentation.height).to eq 1696
        expect(file1.presentation.width).to eq 2548
      end

      it 'files without imageData have empty presentation attribute' do
        file2 = fileSet1.structural.contains.second
        expect(file2.presentation).to eq nil
      end
    end

    context 'when item has identityMetadata objectLabel' do
      before do
        item.identityMetadata.objectLabel = 'Use me'
      end

      it 'prefers objectLabel' do
        expect(cocina_model.label).to eq('Use me')
      end
    end

    context 'when item has an abstract in descMetadata' do
      before do
        item.descMetadata.abstract = 'de Kooning'
      end

      it 'populates note of type summary in cocina model' do
        expect(cocina_model.description.note.first.value).to eq('de Kooning')
        expect(cocina_model.description.note.first.type).to eq('summary')
      end
    end

    context 'when item has a data error' do
      before do
        item.descMetadata.title_info.main_title = nil
        allow(Honeybadger).to receive(:notify)
      end

      it 'raises and Honeybadger notifies' do
        expect { cocina_model }.to raise_error(Cocina::Mapper::MissingTitle)
        expect(Honeybadger).to have_received(:notify).with(instance_of(Cocina::Mapper::MissingTitle), { error_message: '[DATA ERROR] Missing title', tags: 'data_error' })
      end
    end

    context 'when item has a build error' do
      let(:error) { StandardError.new('Mapping mixup') }

      before do
        allow(Cocina::FromFedora::DRO).to receive(:props).and_raise(error)
        allow(Honeybadger).to receive(:notify)
      end

      it 'raises and Honeybadger notifies' do
        expect { cocina_model }.to raise_error(Cocina::Mapper::UnexpectedBuildError)
        expect(Honeybadger).to have_received(:notify).with(error)
      end
    end
  end

  context 'when item is an Etd' do
    let(:item) do
      # ETDs do not have sourceId set, but they do have dissertation in the other_ids
      Etd.new(pid: 'druid:mx000xm0000',
              admin_policy_object_id: 'druid:sc012gz0974',
              other_ids: ['dissertationid:0000005037', 'catkey:11849337', 'uuid:b035c260-9079-11e6-906b-0050569b52d5'],
              label: 'test object')
    end

    before do
      item.descMetadata.mods_title = 'Test ETD'
      allow(item).to receive(:collection_ids).and_return([])
    end

    it 'builds the object with type object, a sourceId, and correct admin policy' do
      expect(cocina_model).to be_kind_of Cocina::Models::DRO
      expect(cocina_model.type).to eq Cocina::Models::Vocab.object

      expect(cocina_model.administrative.hasAdminPolicy).to eq 'druid:sc012gz0974'
      expect(cocina_model.identification.sourceId).to eq 'dissertationid:0000005037'
    end

    context 'with files' do
      let(:content_metadata_ds) { Dor::ContentMetadataDS.from_xml(xml) }

      let(:xml) do
        <<~XML
          <contentMetadata type="file" objectId="druid:dd116zh0343">
            <resource sequence="1" type="folder" id="folder1PuSu">
              <label>Folder 1</label>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="yes" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
                <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2r.txt">
                <checksum type="md5">dc2be64ae43f1c1db4a068603465955d</checksum>
                <checksum type="sha1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
              </file>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="5951" preserve="yes" datetime="2012-06-15T23:00:43Z" id="folder1PuSu/story3m.txt">
                <checksum type="md5">3d67f52e032e36b641d0cad40816f048</checksum>
                <checksum type="sha1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
              </file>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="6307" preserve="yes" datetime="2012-06-15T23:02:22Z" id="folder1PuSu/story4d.txt">
                <checksum type="md5">34f3f646523b0a8504f216483a57bce4</checksum>
                <checksum type="sha1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
              </file>
            </resource>
            <resource sequence="2" type="folder" id="folder2PdSa">
              <file mimetype="text/plain" shelve="no" publish="yes" size="2534" preserve="yes" datetime="2012-06-15T23:05:03Z" id="folder2PdSa/story6u.txt">
                <checksum type="md5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
                <checksum type="sha1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="17074" preserve="yes" datetime="2012-06-15T23:08:35Z" id="folder2PdSa/story7r.txt">
                <checksum type="md5">205271287477c2309512eb664eff9130</checksum>
                <checksum type="sha1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="5643" preserve="yes" datetime="2012-06-15T23:09:26Z" id="folder2PdSa/story8m.txt">
                <checksum type="md5">ce474f4c512953f20a8c4c5b92405cf7</checksum>
                <checksum type="sha1">af9cbf5ab4f020a8bb17b180fbd5c41598d89b37</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="19599" preserve="yes" datetime="2012-06-15T23:14:32Z" id="folder2PdSa/story9d.txt">
                <checksum type="md5">135cb2db6a35afac590687f452053baf</checksum>
                <checksum type="sha1">e74274d7bc06ef44a408a008f5160b3756cb2ab0</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      before do
        allow(content_metadata_ds).to receive(:new?).and_return(false)
        allow(item).to receive(:contentMetadata).and_return(content_metadata_ds)
      end

      it 'builds the object with filesets and files' do
        expect(cocina_model).to be_kind_of Cocina::Models::DRO
        expect(cocina_model.type).to eq Cocina::Models::Vocab.object

        expect(cocina_model.administrative.hasAdminPolicy).to eq 'druid:sc012gz0974'

        expect(cocina_model.structural.contains.size).to eq 2
        folder1 = cocina_model.structural.contains.first
        expect(folder1.label).to eq 'Folder 1'

        file1 = folder1.structural.contains.first
        expect(file1.label).to eq 'folder1PuSu/story1u.txt'
        expect(file1.size).to eq 7888
        expect(file1.hasMimeType).to eq 'text/plain'
        expect(file1.hasMessageDigests.first.digest).to eq '61dfac472b7904e1413e0cbf4de432bda2a97627'
        expect(file1.hasMessageDigests.first.type).to eq 'sha1'
      end
    end
  end

  context 'when item is a Dor::Collection' do
    let(:item) { Dor::Collection.new(pid: 'druid:fh138mm2023', label: 'test object', admin_policy_object_id: 'druid:sc012gz0974') }
    let(:identity_metadata_ds) do
      instance_double(Dor::IdentityMetadataDS, new?: false, ng_xml: Nokogiri::XML(xml), catkey: '777777', source_id: nil)
    end
    let(:xml) do
      <<~XML
        <?xml version="1.0"?>
        <identityMetadata>
          <objectId>druid:fh138mm2023</objectId>
          <objectCreator>DOR</objectCreator>
          <objectLabel>Stanford University map collection, 1853-1997</objectLabel>
          <objectType>collection</objectType>
          <otherId name="catkey">4366577</otherId>
          <otherId name="uuid">3a69d380-d615-11e3-96be-0050569b3c3c</otherId>
          <tag>Remediated By : 5.8.2</tag>
          <release to="Searchworks" what="self" when="2016-11-16T22:45:36Z" who="blalbrit">true</release>
          <release to="Searchworks" what="self" when="2016-11-24T01:16:00Z" who="blalbrit">false</release>
          <release to="Searchworks" what="self" when="2017-07-11T20:28:47Z" who="arcadia">false</release>
          <release to="Searchworks" what="collection" when="2017-07-21T16:38:24Z" who="dhartwig">true</release>
          <release to="Searchworks" what="collection" when="2017-08-23T22:24:27Z" who="dhartwig">true</release>
          <release to="Searchworks" what="collection" when="2018-02-08T21:57:15Z" who="jschne">true</release>
          <release to="Searchworks" what="collection" when="2018-02-16T17:15:54Z" who="jschne">false</release>
          <release to="Searchworks" what="collection" when="2018-02-16T17:20:02Z" who="jschne">true</release>
          <release to="Searchworks" what="collection" when="2018-02-22T17:50:25Z" who="jschne">false</release>
          <release to="Searchworks" what="collection" when="2018-02-22T17:51:12Z" who="jschne">true</release>
          <release to="Searchworks" what="collection" when="2018-02-26T21:12:19Z" who="jschne">true</release>
          <release to="Searchworks" what="self" when="2018-03-01T23:05:01Z" who="jschne">true</release>
          <release to="Earthworks" what="collection" when="2019-10-21T22:06:53Z" who="kdurante">true</release>
        </identityMetadata>
      XML
    end

    before do
      item.descMetadata.title_info.main_title = 'Hello'
      allow(item).to receive(:identityMetadata).and_return(identity_metadata_ds)
    end

    it 'builds the collection with releaseTags' do
      expect(cocina_model).to be_kind_of Cocina::Models::Collection
      expect(cocina_model.administrative.hasAdminPolicy).to eq 'druid:sc012gz0974'
      expect(cocina_model.administrative.releaseTags.size).to eq 13
    end
  end
end
