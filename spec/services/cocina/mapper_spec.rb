# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Mapper do
  subject(:cocina_model) { described_class.build(item) }

  context 'when item is a Dor::Item' do
    let(:item) { Dor::Item.new(pid: 'druid:mx000xm0000', label: 'test object', admin_policy_object_id: 'druid:sc012gz0974') }
    let(:content_metadata_ds) { instance_double(Dor::ContentMetadataDS, new?: false, ng_xml: Nokogiri::XML(xml)) }
    let(:xml) do
      <<~XML
        <contentMetadata type="sample" objectId="druid:dd116zh0343">
          <resource sequence="1" type="folder" id="folder1PuSu">
            <label>Folder 1</label>
            <file shelve="yes" publish="yes" size="7888" preserve="yes" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
              <checksum type="MD5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
              <checksum type="SHA-1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
            </file>
            <file shelve="yes" publish="yes" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2r.txt">
              <checksum type="MD5">dc2be64ae43f1c1db4a068603465955d</checksum>
              <checksum type="SHA-1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
            </file>
            <file shelve="yes" publish="yes" size="5951" preserve="yes" datetime="2012-06-15T23:00:43Z" id="folder1PuSu/story3m.txt">
              <checksum type="MD5">3d67f52e032e36b641d0cad40816f048</checksum>
              <checksum type="SHA-1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
            </file>
            <file shelve="yes" publish="yes" size="6307" preserve="yes" datetime="2012-06-15T23:02:22Z" id="folder1PuSu/story4d.txt">
              <checksum type="MD5">34f3f646523b0a8504f216483a57bce4</checksum>
              <checksum type="SHA-1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
            </file>
          </resource>
          <resource sequence="2" type="folder" id="folder2PdSa">
            <file shelve="no" publish="yes" size="2534" preserve="yes" datetime="2012-06-15T23:05:03Z" id="folder2PdSa/story6u.txt">
              <checksum type="MD5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
              <checksum type="SHA-1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
            </file>
            <file shelve="no" publish="yes" size="17074" preserve="yes" datetime="2012-06-15T23:08:35Z" id="folder2PdSa/story7r.txt">
              <checksum type="MD5">205271287477c2309512eb664eff9130</checksum>
              <checksum type="SHA-1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
            </file>
            <file shelve="no" publish="yes" size="5643" preserve="yes" datetime="2012-06-15T23:09:26Z" id="folder2PdSa/story8m.txt">
              <checksum type="MD5">ce474f4c512953f20a8c4c5b92405cf7</checksum>
              <checksum type="SHA-1">af9cbf5ab4f020a8bb17b180fbd5c41598d89b37</checksum>
            </file>
            <file shelve="no" publish="yes" size="19599" preserve="yes" datetime="2012-06-15T23:14:32Z" id="folder2PdSa/story9d.txt">
              <checksum type="MD5">135cb2db6a35afac590687f452053baf</checksum>
              <checksum type="SHA-1">e74274d7bc06ef44a408a008f5160b3756cb2ab0</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    before do
      allow(item).to receive(:contentMetadata).and_return(content_metadata_ds)
    end

    it 'builds the object with filesets' do
      expect(cocina_model).to be_kind_of Cocina::Models::DRO

      expect(cocina_model.administrative.hasAdminPolicy).to eq 'druid:sc012gz0974'

      expect(cocina_model.structural.contains.size).to eq 2
      folder1 = cocina_model.structural.contains.first
      expect(folder1.label).to eq 'Folder 1'
      expect(folder1.structural.contains.first.label).to eq 'folder1PuSu/story1u.txt'
    end
  end

  context 'when item is a Dor::Collection' do
    let(:item) { Dor::Collection.new(pid: 'druid:fh138mm2023', label: 'test object', admin_policy_object_id: 'druid:sc012gz0974') }

    it 'builds the collection' do
      expect(cocina_model).to be_kind_of Cocina::Models::Collection
      expect(cocina_model.administrative.hasAdminPolicy).to eq 'druid:sc012gz0974'
    end
  end
end
