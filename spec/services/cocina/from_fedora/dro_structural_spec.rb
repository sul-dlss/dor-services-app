# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::DroStructural do
  subject(:structural) { described_class.props(item, type: type) }

  let(:type) { Cocina::Models::Vocab.book }

  let(:item) do
    Dor::Item.new(pid: 'druid:hx013yf6680')
  end
  let(:content_metadata_ds) { instance_double(Dor::ContentMetadataDS, new?: false, ng_xml: Nokogiri::XML(xml)) }

  before do
    allow(item).to receive(:contentMetadata).and_return(content_metadata_ds)
    allow(item).to receive(:collections).and_return([])
    allow(AdministrativeTags).to receive(:content_type).and_return(['file'])
  end

  context 'when a variety of checksum types' do
    let(:xml) do
      <<~XML
        <contentMetadata type="file" stacks="/web-archiving-stacks/data/collections/jt898xc8096" id="druid:hx013yf6680">
          <resource type="file">
            <file dataType="WARC" publish="no" shelve="yes" preserve="yes" id="ARCHIVEIT-5425-TEST-JOB842631-SEED1999838-20190424183402159-00000-h3.warc.gz" size="337857033" mimetype="application/octet-stream">
              <checksum type="MD5">86c3108e4fb762d2b705fe9e64a0d9a2</checksum>
              <checksum type="SHA1">ffed47da235144367c62f9afa09c7394de612136</checksum>
            </file>
          </resource>
          <resource type="file">
            <file dataType="WARC" publish="no" shelve="yes" preserve="yes" id="ARCHIVEIT-5425-QUARTERLY-JOB842817-SEED1032268-20190425070024529-00000-h3.warc.gz" size="24104698" mimetype="application/octet-stream">
              <checksum type="md5">3254a452259fa4aa83371c3998e9d6af</checksum>
              <checksum type="sha1">9c5a8a1823ae7fd8e5ee6e2fb7bfcf7c9270c84d</checksum>
            </file>
          </resource>
          <resource type="file">
            <file dataType="WARC" publish="no" shelve="yes" preserve="yes" id="ARCHIVEIT-5425-QUARTERLY-JOB842817-SEED1032269-20190425070028938-00000-h3.warc.gz" size="2018" mimetype="application/octet-stream">
              <checksum type="FOO5">71da3e6efe912ddd1ee5aeac31c1b763</checksum>
              <checksum type="SHA-1">e5969b8c28e5062897941d9801e2ea9ac67096c9</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it 'normalizes the checksum type' do
      expect(structural[:contains][0][:structural][:contains][0][:hasMessageDigests].size).to eq(2)
      digest1 = structural[:contains][0][:structural][:contains][0][:hasMessageDigests][0]
      expect(digest1[:type]).to eq('sha1')
      expect(digest1[:digest]).to eq('ffed47da235144367c62f9afa09c7394de612136')

      digest2 = structural[:contains][0][:structural][:contains][0][:hasMessageDigests][1]
      expect(digest2[:type]).to eq('md5')
      expect(digest2[:digest]).to eq('86c3108e4fb762d2b705fe9e64a0d9a2')

      expect(structural[:contains][1][:structural][:contains][0][:hasMessageDigests].size).to eq(2)
      digest3 = structural[:contains][1][:structural][:contains][0][:hasMessageDigests][0]
      expect(digest3[:type]).to eq('sha1')
      expect(digest3[:digest]).to eq('9c5a8a1823ae7fd8e5ee6e2fb7bfcf7c9270c84d')

      digest4 = structural[:contains][1][:structural][:contains][0][:hasMessageDigests][1]
      expect(digest4[:type]).to eq('md5')
      expect(digest4[:digest]).to eq('3254a452259fa4aa83371c3998e9d6af')

      expect(structural[:contains][2][:structural][:contains][0][:hasMessageDigests].size).to eq(1)
      digest5 = structural[:contains][2][:structural][:contains][0][:hasMessageDigests][0]
      expect(digest5[:type]).to eq('sha1')
      expect(digest5[:digest]).to eq('e5969b8c28e5062897941d9801e2ea9ac67096c9')
    end
  end

  context 'when item has resources that lack identifiers and labels' do
    before do
      # This gives every file and file set the same UUID. In reality, they would be unique.
      allow(SecureRandom).to receive(:uuid).and_return('123-456-789')
    end

    let(:xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:dd116zh0343">
          <resource>
            <label>Folder 1</label>
            <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
              <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
              <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
            </file>
            <file mimetype="text/plain" shelve="no" publish="no" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2r.txt">
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
          <resource>
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

    it 'builds the object with filesets and files' do
      expect(structural[:contains].size).to eq 2

      resource1 = structural[:contains].first
      expect(resource1[:label]).to eq 'Folder 1'
      expect(resource1[:externalIdentifier]).to eq 'http://cocina.sul.stanford.edu/fileSet/123-456-789'

      resource2 = structural[:contains].second
      expect(resource2[:label]).to eq 'http://cocina.sul.stanford.edu/fileSet/123-456-789'
    end
  end

  context 'with files that have exif data' do
    let(:xml) do
      <<~XML
        <contentMetadata type="file" objectId="druid:dd116zh0343">
          <resource sequence="1" type="file" id="folder1PuSu">
            <label>Folder 1</label>
            <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" datetime="2012-06-15T22:57:43Z" id="folder1PuSu/story1u.txt">
              <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
              <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
            </file>
            <file mimetype="text/plain" shelve="no" publish="no" size="5983" preserve="yes" datetime="2012-06-15T22:58:56Z" id="folder1PuSu/story2r.txt">
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
          <resource sequence="2" type="file" id="folder2PdSa">
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

    it 'builds the object with filesets and files' do
      expect(structural[:contains].size).to eq 2
      folder1 = structural[:contains].first
      expect(folder1[:label]).to eq 'Folder 1'

      file1 = folder1[:structural][:contains].first
      expect(file1[:label]).to eq 'folder1PuSu/story1u.txt'
      expect(file1[:filename]).to eq 'folder1PuSu/story1u.txt'
      expect(file1[:size]).to eq 7888
      expect(file1[:hasMimeType]).to eq 'text/plain'
      expect(file1[:hasMessageDigests].first[:digest]).to eq '61dfac472b7904e1413e0cbf4de432bda2a97627'
      expect(file1[:hasMessageDigests].first[:type]).to eq 'sha1'
      expect(file1[:administrative][:shelve]).to eq true
      expect(file1[:administrative][:sdrPreserve]).to eq false
      expect(file1[:access][:access]).to eq('world')

      file2 = folder1[:structural][:contains][1]
      expect(file2[:administrative][:shelve]).to eq false
      expect(file2[:administrative][:sdrPreserve]).to eq true
      expect(file2[:access][:access]).to eq('dark')
    end
  end

  context "with files that don't have exif data" do
    let(:xml) do
      <<~XML
        <contentMetadata objectId="ck831vq4558" type="file">
          <resource id="ck831vq4558_1" sequence="1" type="file">
            <file id="sul-logo.png" publish="yes" preserve="yes" shelve="yes"/>
          </resource>
        </contentMetadata>
      XML
    end

    it 'builds the object with filesets and files' do
      expect(structural[:contains].size).to eq 1
      resource1 = structural[:contains].first
      file1 = resource1[:structural][:contains].first
      expect(file1[:filename]).to eq 'sul-logo.png'
    end
  end

  context 'when there is an error with solr' do
    let(:xml) do
      <<~XML
        <contentMetadata objectId="ck831vq4558" type="file">
        </contentMetadata>
      XML
    end

    before do
      allow(item).to receive(:collections).and_raise(RSolr::Error::ConnectionRefused)
    end

    it 'raise an error' do
      expect { structural }.to raise_error SolrConnectionError
    end
  end

  context 'with bookData' do
    subject { structural[:hasMemberOrders].first[:viewingDirection] }

    let(:book_data) { "<bookData readingDirection=\"#{reading_direction}\" />" }
    let(:xml) do
      <<~XML
        <contentMetadata type="book" id="druid:hx013yf6680">
          #{book_data}
          <resource id="bb000sc2803_1" sequence="1" type="page">
            <file id="aar_19990525_0001.jp2" preserve="yes" shelve="no" publish="no" size="6765428" mimetype="image/jp2">
              <checksum type="md5">a85c1b8d484fe3d7dee5e0b10d2020de</checksum>
              <checksum type="sha1">ccb1cd8bf179d7049a3e1164a369d35061ea23a2</checksum>
              <imageData width="5992" height="9041"/>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    context 'when readingDirection is "rtl"' do
      let(:reading_direction) { 'rtl' }

      it { is_expected.to eq 'right-to-left' }
    end

    context 'when readingDirection is "ltr"' do
      let(:reading_direction) { 'ltr' }

      it { is_expected.to eq 'left-to-right' }
    end

    context "when bookData doesn't exist" do
      before do
        allow(AdministrativeTags).to receive(:content_type).with(pid: item.id).and_return(content_type)
      end

      let(:book_data) { nil }

      context "when content type is ['Book (rtl)']" do
        let(:content_type) { ['Book (rtl)'] }

        it { is_expected.to eq 'right-to-left' }
      end

      context "when content type is ['Book (flipbook, ltr)']" do
        let(:content_type) { ['Book (flipbook, ltr)'] }

        it { is_expected.to eq 'left-to-right' }
      end

      context "when content type is ['Book (flipbook, rtl)']" do
        let(:content_type) { ['Book (flipbook, rtl)'] }

        it { is_expected.to eq 'right-to-left' }
      end

      context "when content type is ['Manuscript (flipbook, ltr)']" do
        let(:content_type) { ['Manuscript (flipbook, ltr)'] }

        it { is_expected.to eq 'left-to-right' }
      end

      context "when content type is ['Manuscript (ltr)']" do
        let(:content_type) { ['Manuscript (ltr)'] }

        it { is_expected.to eq 'left-to-right' }
      end
    end
  end

  context 'when there is a transcript' do
    subject { file2[:use] }

    let(:resource1) { structural[:contains].first }
    let(:file2) { resource1[:structural][:contains].second }

    let(:xml) do
      <<~XML
        <contentMetadata type="book" id="druid:hx013yf6680">
          <resource id="cd027gx5097_1" sequence="1" type="page">
            <label>Page 1</label>
            <file id="cd027gx5097_0001.tif" mimetype="image/tiff" size="48151214" publish="no" shelve="no" preserve="yes">
              <checksum type="sha1">7f772a52f4b851c2a33addd357f5132d67043b50</checksum>
              <checksum type="md5">faa48cebd1ca4a09a646399d7088b3f2</checksum>
              <imageData height="6806" width="5339"/>
            </file>
            <file id="cd027gx5097_0001.xml" mimetype="application/xml" size="74861" publish="yes" shelve="yes" preserve="yes" role="transcription">
              <checksum type="sha1">959fe418e26d271a52f2133518b34c01cad4921f</checksum>
              <checksum type="md5">da80f0e0212caf85b5a76c9ef99a9222</checksum>
            </file>
          </resource>
        </contentMetadata>
      XML
    end

    it { is_expected.to eq 'transcription' }
  end
end
