# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fedora item content metadata <--> Cocina DRO structural mappings' do
  context 'when a typical content metadata' do
    it_behaves_like 'DRO Structural Fedora Cocina mapping' do
      let(:content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <bookData readingOrder="ltr"/>
            <resource sequence="1" type="file" id="folder1PuSu">
              <label>Folder 1</label>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
                <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="no" size="5983" preserve="yes" id="folder1PuSu/story2r.txt">
                <checksum type="md5">dc2be64ae43f1c1db4a068603465955d</checksum>
                <checksum type="sha1">b8a672c1848fc3d13b5f380e15835690e24600e0</checksum>
              </file>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="5951" preserve="yes" id="folder1PuSu/story3m.txt">
                <checksum type="md5">3d67f52e032e36b641d0cad40816f048</checksum>
                <checksum type="sha1">548f349c79928b6d0996b7ff45990bdce5ee9753</checksum>
              </file>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="6307" preserve="yes" id="folder1PuSu/story4d.txt">
                <checksum type="md5">34f3f646523b0a8504f216483a57bce4</checksum>
                <checksum type="sha1">d498b513add5bb138ed4f6205453a063a2434dc4</checksum>
              </file>
            </resource>
            <resource sequence="2" type="file" id="folder2PdSa">
              <file mimetype="text/plain" shelve="no" publish="yes" size="2534" preserve="yes" id="folder2PdSa/story6u.txt">
                <checksum type="md5">1f15cc786bfe832b2fa1e6f047c500ba</checksum>
                <checksum type="sha1">bf3af01de2afa15719d8c42a4141e3b43d06fef6</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="17074" preserve="yes" id="folder2PdSa/story7r.txt">
                <checksum type="md5">205271287477c2309512eb664eff9130</checksum>
                <checksum type="sha1">b23aa592ab673030ace6178e29fad3cf6a45bd32</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="5643" preserve="yes" id="folder2PdSa/story8m.txt">
                <checksum type="md5">ce474f4c512953f20a8c4c5b92405cf7</checksum>
                <checksum type="sha1">af9cbf5ab4f020a8bb17b180fbd5c41598d89b37</checksum>
              </file>
              <file mimetype="text/plain" shelve="no" publish="yes" size="19599" preserve="yes" id="folder2PdSa/story9d.txt">
                <checksum type="md5">135cb2db6a35afac590687f452053baf</checksum>
                <checksum type="sha1">e74274d7bc06ef44a408a008f5160b3756cb2ab0</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      let(:cocina_structural_props) do
        { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                       version: 1,
                       structural: { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story1u.txt',
                                                  filename: 'folder1PuSu/story1u.txt',
                                                  size: 7888,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                      { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: false, shelve: true },
                                                  hasMimeType: 'text/plain' },
                                                { externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story2r.txt',
                                                  filename: 'folder1PuSu/story2r.txt',
                                                  size: 5983,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: 'b8a672c1848fc3d13b5f380e15835690e24600e0' },
                                                                      { type: 'md5', digest: 'dc2be64ae43f1c1db4a068603465955d' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: false, sdrPreserve: true, shelve: false },
                                                  hasMimeType: 'text/plain' },
                                                { externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story3m.txt',
                                                  filename: 'folder1PuSu/story3m.txt',
                                                  size: 5951,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: '548f349c79928b6d0996b7ff45990bdce5ee9753' },
                                                                      { type: 'md5', digest: '3d67f52e032e36b641d0cad40816f048' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: true },
                                                  hasMimeType: 'text/plain' },
                                                { externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story4d.txt',
                                                  filename: 'folder1PuSu/story4d.txt',
                                                  size: 6307,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: 'd498b513add5bb138ed4f6205453a063a2434dc4' },
                                                                      { type: 'md5', digest: '34f3f646523b0a8504f216483a57bce4' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: true },
                                                  hasMimeType: 'text/plain' }] },
                       label: 'Folder 1' },
                     { externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                       version: 1,
                       structural: { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder2PdSa/story6u.txt',
                                                  filename: 'folder2PdSa/story6u.txt',
                                                  size: 2534,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: 'bf3af01de2afa15719d8c42a4141e3b43d06fef6' },
                                                                      { type: 'md5', digest: '1f15cc786bfe832b2fa1e6f047c500ba' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: false },
                                                  hasMimeType: 'text/plain' },
                                                { externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder2PdSa/story7r.txt',
                                                  filename: 'folder2PdSa/story7r.txt',
                                                  size: 17074,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: 'b23aa592ab673030ace6178e29fad3cf6a45bd32' },
                                                                      { type: 'md5', digest: '205271287477c2309512eb664eff9130' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: false },
                                                  hasMimeType: 'text/plain' },
                                                { externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder2PdSa/story8m.txt',
                                                  filename: 'folder2PdSa/story8m.txt',
                                                  size: 5643,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: 'af9cbf5ab4f020a8bb17b180fbd5c41598d89b37' },
                                                                      { type: 'md5', digest: 'ce474f4c512953f20a8c4c5b92405cf7' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: false },
                                                  hasMimeType: 'text/plain' },
                                                { externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder2PdSa/story9d.txt',
                                                  filename: 'folder2PdSa/story9d.txt',
                                                  size: 19599,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: 'e74274d7bc06ef44a408a008f5160b3756cb2ab0' },
                                                                      { type: 'md5', digest: '135cb2db6a35afac590687f452053baf' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: true, shelve: false },
                                                  hasMimeType: 'text/plain' }] },
                       label: '' }], hasMemberOrders: [{ viewingDirection: 'left-to-right' }] }
      end
    end
  end

  context 'when content metadata with label attr (e.g., legacy ETD)' do
    it_behaves_like 'DRO Structural Fedora Cocina mapping' do
      # See druid:bb164pj1759
      let(:content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <bookData readingOrder="ltr"/>
            <resource sequence="1" type="file" id="folder1PuSu">
              <attr type="label">Folder 1</attr>
              <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
                <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      let(:roundtrip_content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <bookData readingOrder="ltr"/>
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

      let(:cocina_structural_props) do
        { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                       version: 1,
                       structural: { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story1u.txt',
                                                  filename: 'folder1PuSu/story1u.txt',
                                                  size: 7888,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                      { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: false, shelve: true },
                                                  hasMimeType: 'text/plain' }] },
                       label: 'Folder 1' }], hasMemberOrders: [{ viewingDirection: 'left-to-right' }] }
      end
    end
  end

  context 'when blank mimetype' do
    it_behaves_like 'DRO Structural Fedora Cocina mapping' do
      let(:content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <bookData readingOrder="ltr"/>
            <resource sequence="1" type="file" id="folder1PuSu">
              <label>Folder 1</label>
              <file mimetype="" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
                <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      let(:cocina_structural_props) do
        { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                       version: 1,
                       structural: { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story1u.txt',
                                                  filename: 'folder1PuSu/story1u.txt',
                                                  size: 7888,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                      { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: false, shelve: true } }] },
                       label: 'Folder 1' }], hasMemberOrders: [{ viewingDirection: 'left-to-right' }] }
      end
    end
  end

  context 'when no publish but there is deliver' do
    it_behaves_like 'DRO Structural Fedora Cocina mapping' do
      let(:content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <resource sequence="1" type="file" id="folder1PuSu">
            <label>Folder 1</label>
              <file mimetype="text/plain" shelve="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt" deliver="yes">
                <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
                <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
              </file>
            </resource>
          </contentMetadata>
        XML
      end

      let(:roundtrip_content_xml) do
        <<~XML
          <contentMetadata type="book" objectId="#{druid}">
            <bookData readingOrder="ltr"/>
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

      let(:cocina_structural_props) do
        { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                       type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                       version: 1,
                       structural: { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                  label: 'folder1PuSu/story1u.txt',
                                                  filename: 'folder1PuSu/story1u.txt',
                                                  size: 7888,
                                                  version: 1,
                                                  hasMessageDigests: [{ type: 'sha1',
                                                                        digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                      { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                  access: { access: 'world', download: 'world' },
                                                  administrative: { publish: true, sdrPreserve: false, shelve: true },
                                                  hasMimeType: 'text/plain' }] },
                       label: 'Folder 1' }], hasMemberOrders: [{ viewingDirection: 'left-to-right' }] }
      end
    end
  end
end
