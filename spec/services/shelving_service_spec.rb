# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvingService do
  let(:druid) { 'druid:ng782rw8378' }

  let(:cocina_object) do
    instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural:, type: Cocina::Models::ObjectType.book)
  end

  let(:structural) do
    Cocina::Models::DROStructural.new(
      { contains: [{ externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                     type: Cocina::Models::FileSetType.file,
                     version: 1,
                     structural: { contains: [{ externalIdentifier: 'https://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                type: Cocina::Models::ObjectType.file,
                                                label: 'folder1PuSu/story1u.txt',
                                                filename: 'folder1PuSu/story1u.txt',
                                                size: 7888,
                                                version: 1,
                                                hasMessageDigests: [{ type: 'sha1',
                                                                      digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                    { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                access: { view: 'world', download: 'world' },
                                                administrative: { publish: true, sdrPreserve: false, shelve: true },
                                                hasMimeType: 'text/plain' }] },
                     label: 'Folder 1' }],
        isMemberOf: collections }
    )
  end

  let(:collections) { ['druid:bb077hj4590'] }

  let(:content_metadata) do
    <<~XML
      <contentMetadata type="book" objectId="#{druid}">
        <resource sequence="1" type="file" id="folder1PuSu">
          <label>Folder 1</label>
          <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
            <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
            <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
          </file>
        </resource>
      </contentMetadata>
    XML
  end

  let(:previous_content_metadata) { content_metadata }
  let(:stacks_root) { Dir.mktmpdir }
  let(:workspace_root) { Dir.mktmpdir }
  let(:mock_shelve_diff) { instance_double(Moab::FileGroupDifference) }
  let(:group_difference) { instance_double(Moab::FileGroupDifference) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflows:) }
  let(:workflows) { ['accessionWF', 'registrationWF'] }
  let(:stacks_object_pathname) { Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Settings.stacks).to receive_messages(local_stacks_root: stacks_root, local_workspace_root: workspace_root)
    allow(Cocina::ToXml::ContentMetadataGenerator).to receive(:generate).and_return(content_metadata)
    allow(Preservation::Client.objects).to receive(:metadata).with(druid:, filepath: 'contentMetadata.xml').and_return(previous_content_metadata)
    allow(Preservation::Client.objects).to receive(:current_version).with(druid).and_return(1)
    allow(ShelvableFilesStager).to receive(:stage)
    allow(DigitalStacksService).to receive(:remove_from_stacks)
    allow(DigitalStacksService).to receive(:rename_in_stacks)
    allow(DigitalStacksService).to receive(:shelve_to_stacks)
  end

  after do
    FileUtils.remove_entry stacks_root
    FileUtils.remove_entry workspace_root
  end

  context 'when structural present and previous version exists in preservation' do
    it 'pushes file changes for shelve-able files into the stacks' do
      stacks_object_pathname = Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path)
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      described_class.shelve(cocina_object)
      expect(ShelvableFilesStager).to have_received(:stage).with(druid, Moab::FileGroupDifference, Moab::FileGroupDifference, Pathname)
      expect(DigitalStacksService).to have_received(:remove_from_stacks).with(stacks_object_pathname, Moab::FileGroupDifference)
      expect(DigitalStacksService).to have_received(:rename_in_stacks).with(stacks_object_pathname, Moab::FileGroupDifference)
      expect(DigitalStacksService).to have_received(:shelve_to_stacks).with(Pathname, stacks_object_pathname, Moab::FileGroupDifference)
      expect(Cocina::ToXml::ContentMetadataGenerator).to have_received(:generate).with(druid:, structural:, type: Cocina::Models::ObjectType.book)
    end
  end

  context 'when structural present and initial version' do
    before do
      allow(Preservation::Client.objects).to receive(:current_version).with(druid).and_raise(Preservation::Client::NotFoundError)
      allow(Preservation::Client.objects).to receive(:metadata).and_raise(Preservation::Client::NotFoundError)
    end

    it 'pushes file changes for shelve-able files into the stacks' do
      stacks_object_pathname = Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path)
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      described_class.shelve(cocina_object)
      expect(ShelvableFilesStager).to have_received(:stage).with(druid, Moab::FileGroupDifference, Moab::FileGroupDifference, Pathname)
      expect(DigitalStacksService).to have_received(:remove_from_stacks).with(stacks_object_pathname, Moab::FileGroupDifference)
      expect(DigitalStacksService).to have_received(:rename_in_stacks).with(stacks_object_pathname, Moab::FileGroupDifference)
      expect(DigitalStacksService).to have_received(:shelve_to_stacks).with(Pathname, stacks_object_pathname, Moab::FileGroupDifference)
      expect(Cocina::ToXml::ContentMetadataGenerator).to have_received(:generate).with(druid:, structural:, type: Cocina::Models::ObjectType.book)
    end
  end

  context 'when structural absent' do
    let(:structural) { nil }

    it 'raises' do
      expect { described_class.shelve(cocina_object) }.to raise_error(ShelvingService::ShelvingError)
    end
  end

  context 'when a web archive' do
    let(:workflows) { %w[accessionWF registrationWF wasCrawlPreassemblyWF] }
    let(:stacks_object_pathname) { Pathname('/web-archiving-stacks/data/collections/bb077hj4590/ng/782/rw/8378') }

    it 'pushes file changes for shelve-able files into the stacks' do
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      described_class.shelve(cocina_object)
      expect(ShelvableFilesStager).to have_received(:stage).with(druid, Moab::FileGroupDifference, Moab::FileGroupDifference, Pathname)
      expect(DigitalStacksService).to have_received(:remove_from_stacks).with(stacks_object_pathname, Moab::FileGroupDifference)
      expect(DigitalStacksService).to have_received(:rename_in_stacks).with(stacks_object_pathname, Moab::FileGroupDifference)
      expect(DigitalStacksService).to have_received(:shelve_to_stacks).with(Pathname, stacks_object_pathname, Moab::FileGroupDifference)
      expect(Cocina::ToXml::ContentMetadataGenerator).to have_received(:generate).with(druid:, structural:, type: Cocina::Models::ObjectType.book)
    end
  end

  context 'when a web archive without collection' do
    let(:workflows) { %w[accessionWF registrationWF wasCrawlPreassemblyWF] }
    let(:collections) { [] }

    it 'raises' do
      expect { described_class.shelve(cocina_object) }.to raise_error(ShelvingService::ShelvingError)
    end
  end

  context 'when shelve_to_purl_fetcher is enabled' do
    let(:previous_content_metadata) do
      <<~XML
        <contentMetadata type="book" objectId="#{druid}">
        </contentMetadata>
      XML
    end

    let(:expected_file_metadata) do
      {
        'folder1PuSu/story1u.txt' =>
      PurlFetcher::Client::DirectUploadRequest.new(
        checksum: '4oN7nwLgsLdvUm7rgceqew==',
        byte_size: 7888,
        content_type: 'application/octet-stream',
        filename: 'folder1PuSu/story1u.txt'
      )
      }
    end

    let(:expected_filepath_map) do
      {
        'folder1PuSu/story1u.txt' => "#{workspace_root}/ng/782/rw/8378/ng782rw8378/content/folder1PuSu/story1u.txt"
      }
    end

    before do
      allow(Settings.enabled_features).to receive(:shelve_to_purl_fetcher).and_return(true)
      allow(PurlFetcher::Client::UploadFiles).to receive(:upload)
      allow(Honeybadger).to receive(:notify)
    end

    it 'uploads the files to purl-fetcher' do
      described_class.shelve(cocina_object)
      expect(PurlFetcher::Client::UploadFiles).to have_received(:upload).with(file_metadata: expected_file_metadata, filepath_map: expected_filepath_map)
      expect(Honeybadger).not_to have_received(:notify)
    end

    context 'when an error occurs' do
      before do
        allow(PurlFetcher::Client::UploadFiles).to receive(:upload).and_raise(StandardError)
      end

      it 'notifies Honeybadger' do
        described_class.shelve(cocina_object)
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end

  describe '#content_diff' do
    let(:shelving_service) { described_class.new(cocina_object) }

    context 'with all subset' do
      let(:previous_content_metadata) { read_fixture('content_diff_reports/jq937jp0017/v0001/metadata/contentMetadata.xml') }

      # mock the current object content metadata (which would be converted from cocina for SDR object)
      before do
        allow(shelving_service)
          .to receive(:content_metadata)
          .and_return(read_fixture('content_diff_reports/jq937jp0017/v0002/metadata/contentMetadata.xml'))
      end

      it 'returns expected Moab::FileGroupDifference' do
        diff = shelving_service.send(:content_diff, 'all')
        diff_ng_xml = Nokogiri::XML(diff.to_xml)
        exp_xml = <<-XML
          <fileGroupDifference groupId="content" differenceCount="3" identical="3" copyadded="0" copydeleted="0" renamed="0" modified="1" deleted="2" added="0">
            <subset change="identical" count="3">
              <file change="identical" basisPath="title.jpg" otherPath="same">
                <fileSignature size="40873" md5="1a726cd7963bd6d3ceb10a8c353ec166" sha1="583220e0572640abcd3ddd97393d224e8053a6ad" sha256=""/>
              </file>
              <file change="identical" basisPath="page-2.jpg" otherPath="same">
                <fileSignature size="39450" md5="82fc107c88446a3119a51a8663d1e955" sha1="d0857baa307a2e9efff42467b5abd4e1cf40fcd5" sha256=""/>
              </file>
              <file change="identical" basisPath="page-3.jpg" otherPath="same">
                <fileSignature size="19125" md5="a5099878de7e2e064432d6df44ca8827" sha1="c0ccac433cf02a6cee89c14f9ba6072a184447a2" sha256=""/>
              </file>
            </subset>
            <subset change="copyadded" count="0"/>
            <subset change="copydeleted" count="0"/>
            <subset change="renamed" count="0"/>
            <subset change="modified" count="1">
              <file change="modified" basisPath="page-1.jpg" otherPath="same">
                <fileSignature size="25153" md5="3dee12fb4f1c28351c7482b76ff76ae4" sha1="906c1314f3ab344563acbbbe2c7930f08429e35b" sha256=""/>
                <fileSignature size="32915" md5="c1c34634e2f18a354cd3e3e1574c3194" sha1="0616a0bd7927328c364b2ea0b4a79c507ce915ed" sha256=""/>
              </file>
            </subset>
            <subset change="deleted" count="2">
              <file change="deleted" basisPath="intro-1.jpg" otherPath="">
                <fileSignature size="41981" md5="915c0305bf50c55143f1506295dc122c" sha1="60448956fbe069979fce6a6e55dba4ce1f915178" sha256=""/>
              </file>
              <file change="deleted" basisPath="intro-2.jpg" otherPath="">
                <fileSignature size="39850" md5="77f1a4efdcea6a476505df9b9fba82a7" sha1="a49ae3f3771d99ceea13ec825c9c2b73fc1a9915" sha256=""/>
              </file>
            </subset>
            <subset change="added" count="0"/>
        </fileGroupDifference>
        XML
        expect(diff_ng_xml).to be_equivalent_to(Nokogiri::XML(exp_xml))
      end
    end

    context 'with shelve subset' do
      # read a fixture for the previous version content metadata coming from preservation
      # there is a mock at the top of this test that allows this to be read by the diffing code
      let(:previous_content_metadata) { read_fixture('content_diff_reports/dd116zh0343/v0001/metadata/contentMetadata.xml') }

      # mock the current object content metadata (which would be converted from cocina for SDR object)
      before do
        allow(shelving_service)
          .to receive(:content_metadata)
          .and_return(read_fixture('content_diff_reports/dd116zh0343/v0002/metadata/contentMetadata.xml'))
      end

      it 'returns expected Moab::FileGroupDifference' do
        diff = shelving_service.send(:content_diff, 'shelve')
        diff_ng_xml = Nokogiri::XML(diff.to_xml)
        exp_xml = <<-XML
          <fileGroupDifference groupId="content" differenceCount="12" identical="1" copyadded="0" copydeleted="0" renamed="1" modified="1" deleted="5" added="5">
            <subset change="identical" count="1">
              <file change="identical" basisPath="folder1PuSu/story1u.txt" otherPath="same">
                <fileSignature size="7888" md5="e2837b9f02e0b0b76f526eeb81c7aa7b" sha1="61dfac472b7904e1413e0cbf4de432bda2a97627" sha256=""/>
              </file>
            </subset>
            <subset change="copyadded" count="0"/>
            <subset change="copydeleted" count="0"/>
            <subset change="renamed" count="1">
              <file change="renamed" basisPath="folder1PuSu/story2r.txt" otherPath="folder1PuSu/story2rr.txt">
                <fileSignature size="5983" md5="dc2be64ae43f1c1db4a068603465955d" sha1="b8a672c1848fc3d13b5f380e15835690e24600e0" sha256=""/>
              </file>
            </subset>
            <subset change="modified" count="1">
              <file change="modified" basisPath="folder1PuSu/story3m.txt" otherPath="same">
                <fileSignature size="5951" md5="3d67f52e032e36b641d0cad40816f048" sha1="548f349c79928b6d0996b7ff45990bdce5ee9753" sha256=""/>
                <fileSignature size="5941" md5="1e5579b16888678f24a1b7008ba15f75" sha1="045245ae45508f92ef82f03eb54290dce92fca64" sha256=""/>
              </file>
            </subset>
            <subset change="deleted" count="5">
              <file change="deleted" basisPath="folder1PuSu/story4d.txt" otherPath="">
                <fileSignature size="6307" md5="34f3f646523b0a8504f216483a57bce4" sha1="d498b513add5bb138ed4f6205453a063a2434dc4" sha256=""/>
              </file>
              <file change="deleted" basisPath="folder3PaSd/storyBu.txt" otherPath="">
                <fileSignature size="14964" md5="8f0a828f3e63cd18232c191ab0c5805c" sha1="b6cb7aa60dd07b4dcc6ab709437e574912f25f30" sha256=""/>
              </file>
              <file change="deleted" basisPath="folder3PaSd/storyCr.txt" otherPath="">
                <fileSignature size="23485" md5="3486492e40b4c342b25ae4f9c64f06ee" sha1="a1654e9d3cf80242cc3669f89fb41b2ec5e62cb7" sha256=""/>
              </file>
              <file change="deleted" basisPath="folder3PaSd/storyDm.txt" otherPath="">
                <fileSignature size="25336" md5="233228c7e1f473dad1d2c673157dd809" sha1="83c57f595aa6a72f80d47900cc0d10e589f31ea5" sha256=""/>
              </file>
              <file change="deleted" basisPath="folder3PaSd/storyEd.txt" otherPath="">
                <fileSignature size="41765" md5="0e57176032451fd6d0509b6172790b8f" sha1="b191e11dc1768c47852e6d2a235094843be358ff" sha256=""/>
              </file>
            </subset>
            <subset change="added" count="5">
              <file change="added" basisPath="" otherPath="folder1PuSu/story5a.txt">
                <fileSignature size="3614" md5="c7535886a1d0e6d226da322b6ef0bc99" sha1="524deed114c5090af42eae42d0adacb4f212a270" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/story6u.txt">
                <fileSignature size="2534" md5="1f15cc786bfe832b2fa1e6f047c500ba" sha1="bf3af01de2afa15719d8c42a4141e3b43d06fef6" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/story7rr.txt">
                <fileSignature size="17074" md5="205271287477c2309512eb664eff9130" sha1="b23aa592ab673030ace6178e29fad3cf6a45bd32" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/story8m.txt">
                <fileSignature size="5645" md5="f773d6e161000c5b9f90a96cd071688a" sha1="ed5a5a84d51f94bbd04924bc4c982634ee197a62" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/storyAa.txt">
                <fileSignature size="10717" md5="aeb1721bbf64aebb3ff58cb05d34bd18" sha1="e29f5847ef5645d60e8c0caf99b3fce5e9f645c9" sha256=""/>
              </file>
            </subset>
          </fileGroupDifference>
        XML
        expect(diff_ng_xml).to be_equivalent_to(Nokogiri::XML(exp_xml))
      end
    end

    context 'with preserve subset' do
      # read a fixture for the previous version content metadata coming from preservation
      # there is a mock at the top of this test that allows this to be read by the diffing code
      let(:previous_content_metadata) { read_fixture('content_diff_reports/dd116zh0343/v0001/metadata/contentMetadata.xml') }

      # mock the current object content metadata (which would be converted from cocina for SDR object)
      before do
        allow(shelving_service)
          .to receive(:content_metadata)
          .and_return(read_fixture('content_diff_reports/dd116zh0343/v0002/metadata/contentMetadata.xml'))
      end

      it 'returns expected Moab::FileGroupDifference' do
        diff = shelving_service.send(:content_diff, 'preserve')
        diff_ng_xml = Nokogiri::XML(diff.to_xml)
        exp_xml = <<-XML
          <fileGroupDifference groupId="content" differenceCount="12" identical="1" copyadded="0" copydeleted="0" renamed="1" modified="1" added="5" deleted="5">
          <subset change="identical" count="1">
            <file change="identical" basisPath="folder1PuSu/story1u.txt" otherPath="same">
              <fileSignature size="7888" md5="e2837b9f02e0b0b76f526eeb81c7aa7b" sha1="61dfac472b7904e1413e0cbf4de432bda2a97627" sha256=""/>
            </file>
          </subset>
          <subset change="renamed" count="1">
            <file change="renamed" basisPath="folder1PuSu/story2r.txt" otherPath="folder1PuSu/story2rr.txt">
              <fileSignature size="5983" md5="dc2be64ae43f1c1db4a068603465955d" sha1="b8a672c1848fc3d13b5f380e15835690e24600e0" sha256=""/>
            </file>
          </subset>
          <subset change="modified" count="1">
            <file change="modified" basisPath="folder1PuSu/story3m.txt" otherPath="same">
              <fileSignature size="5951" md5="3d67f52e032e36b641d0cad40816f048" sha1="548f349c79928b6d0996b7ff45990bdce5ee9753" sha256=""/>
              <fileSignature size="5941" md5="1e5579b16888678f24a1b7008ba15f75" sha1="045245ae45508f92ef82f03eb54290dce92fca64" sha256=""/>
            </file>
          </subset>
          <subset change="added" count="5">
            <file change="added" basisPath="" otherPath="folder1PuSu/story5a.txt">
              <fileSignature size="3614" md5="c7535886a1d0e6d226da322b6ef0bc99" sha1="524deed114c5090af42eae42d0adacb4f212a270" sha256=""/>
            </file>
            <file change="added" basisPath="" otherPath="folder3PaSd/storyBu.txt">
              <fileSignature size="14964" md5="8f0a828f3e63cd18232c191ab0c5805c" sha1="b6cb7aa60dd07b4dcc6ab709437e574912f25f30" sha256=""/>
            </file>
            <file change="added" basisPath="" otherPath="folder3PaSd/storyCrr.txt">
              <fileSignature size="23485" md5="3486492e40b4c342b25ae4f9c64f06ee" sha1="a1654e9d3cf80242cc3669f89fb41b2ec5e62cb7" sha256=""/>
            </file>
            <file change="added" basisPath="" otherPath="folder3PaSd/storyDm.txt">
              <fileSignature size="25336" md5="90226a21d2dc9185c7b2947cf71c1865" sha1="aae63966b21df4b24cd5cd91021ae55b37811a03" sha256=""/>
            </file>
            <file change="added" basisPath="" otherPath="folder3PaSd/storyFa.txt">
              <fileSignature size="28726" md5="4b4879a7e56b447f0c3826c2f64be603" sha1="686ac9a8e7187718dc1e0d3fa65ab906dff6698a" sha256=""/>
            </file>
          </subset>
          <subset change="deleted" count="5">
            <file change="deleted" basisPath="folder1PuSu/story4d.txt" otherPath="">
              <fileSignature size="6307" md5="34f3f646523b0a8504f216483a57bce4" sha1="d498b513add5bb138ed4f6205453a063a2434dc4" sha256=""/>
            </file>
            <file change="deleted" basisPath="folder2PdSa/story6u.txt" otherPath="">
              <fileSignature size="2534" md5="1f15cc786bfe832b2fa1e6f047c500ba" sha1="bf3af01de2afa15719d8c42a4141e3b43d06fef6" sha256=""/>
            </file>
            <file change="deleted" basisPath="folder2PdSa/story7r.txt" otherPath="">
              <fileSignature size="17074" md5="205271287477c2309512eb664eff9130" sha1="b23aa592ab673030ace6178e29fad3cf6a45bd32" sha256=""/>
            </file>
            <file change="deleted" basisPath="folder2PdSa/story8m.txt" otherPath="">
              <fileSignature size="5643" md5="ce474f4c512953f20a8c4c5b92405cf7" sha1="af9cbf5ab4f020a8bb17b180fbd5c41598d89b37" sha256=""/>
            </file>
            <file change="deleted" basisPath="folder2PdSa/story9d.txt" otherPath="">
              <fileSignature size="19599" md5="135cb2db6a35afac590687f452053baf" sha1="e74274d7bc06ef44a408a008f5160b3756cb2ab0" sha256=""/>
            </file>
          </subset>
          <subset change="copyadded" count="0"/>
          <subset change="copydeleted" count="0"/>
        </fileGroupDifference>
        XML
        expect(diff_ng_xml).to be_equivalent_to(Nokogiri::XML(exp_xml))
      end
    end

    context 'with shelve subset and without specified previous version' do
      # mock preservation client call not finding a preserved object and
      # mock the current object content metadata (which would be converted from cocina for SDR object)
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(druid).and_raise(Preservation::Client::NotFoundError)
        allow(shelving_service)
          .to receive(:content_metadata)
          .and_return(read_fixture('content_diff_reports/dd116zh0343/v0002/metadata/contentMetadata.xml'))
      end

      it 'returns expected Moab::FileInventoryDifference' do
        diff = shelving_service.send(:content_diff, 'shelve')
        diff_ng_xml = Nokogiri::XML(diff.to_xml)
        exp_xml = <<-XML
          <fileGroupDifference groupId="content" differenceCount="8" identical="0" copyadded="0" copydeleted="0" renamed="0" modified="0" deleted="0" added="8">
            <subset change="identical" count="0"/>
            <subset change="copyadded" count="0"/>
            <subset change="copydeleted" count="0"/>
            <subset change="renamed" count="0"/>
            <subset change="modified" count="0"/>
            <subset change="deleted" count="0"/>
            <subset change="added" count="8">
              <file change="added" basisPath="" otherPath="folder1PuSu/story1u.txt">
                <fileSignature size="7888" md5="e2837b9f02e0b0b76f526eeb81c7aa7b" sha1="61dfac472b7904e1413e0cbf4de432bda2a97627" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder1PuSu/story2rr.txt">
                <fileSignature size="5983" md5="dc2be64ae43f1c1db4a068603465955d" sha1="b8a672c1848fc3d13b5f380e15835690e24600e0" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder1PuSu/story3m.txt">
                <fileSignature size="5941" md5="1e5579b16888678f24a1b7008ba15f75" sha1="045245ae45508f92ef82f03eb54290dce92fca64" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder1PuSu/story5a.txt">
                <fileSignature size="3614" md5="c7535886a1d0e6d226da322b6ef0bc99" sha1="524deed114c5090af42eae42d0adacb4f212a270" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/story6u.txt">
                <fileSignature size="2534" md5="1f15cc786bfe832b2fa1e6f047c500ba" sha1="bf3af01de2afa15719d8c42a4141e3b43d06fef6" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/story7rr.txt">
                <fileSignature size="17074" md5="205271287477c2309512eb664eff9130" sha1="b23aa592ab673030ace6178e29fad3cf6a45bd32" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/story8m.txt">
                <fileSignature size="5645" md5="f773d6e161000c5b9f90a96cd071688a" sha1="ed5a5a84d51f94bbd04924bc4c982634ee197a62" sha256=""/>
              </file>
              <file change="added" basisPath="" otherPath="folder2PdSa/storyAa.txt">
                <fileSignature size="10717" md5="aeb1721bbf64aebb3ff58cb05d34bd18" sha1="e29f5847ef5645d60e8c0caf99b3fce5e9f645c9" sha256=""/>
              </file>
            </subset>
          </fileGroupDifference>
        XML
        expect(diff_ng_xml).to be_equivalent_to(Nokogiri::XML(exp_xml))
      end
    end
  end
end
