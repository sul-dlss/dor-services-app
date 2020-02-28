# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContentMetadataGenerator do
  subject(:generate) do
    described_class.generate(druid: 'druid:bc123de5678', object: model)
  end

  let(:model) do
    Cocina::Models.build_request(JSON.parse(data))
  end

  let(:druid) { 'druid:bc123de5678' }

  let(:file1) do
    {
      'version' => 1,
      'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
      'filename' => '00001.html',
      'label' => '00001.html',
      'hasMimeType' => 'text/html',
      'use' => 'transcription',
      'size' => 997,
      'administrative' => {
        'sdrPreserve' => true,
        'shelve' => false
      },
      'access' => {
        'access' => 'dark'
      },
      'hasMessageDigests' => [
        {
          'type' => 'sha1',
          'digest' => 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
        },
        {
          'type' => 'md5',
          'digest' => 'e6d52da47a5ade91ae31227b978fb023'
        }

      ]
    }
  end

  let(:file2) do
    {
      'version' => 1,
      'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
      'filename' => '00001.jp2',
      'label' => '00001.jp2',
      'hasMimeType' => 'image/jp2',
      'size' => 149570,
      'administrative' => {
        'sdrPreserve' => true,
        'shelve' => true
      },
      'access' => {
        'access' => 'stanford'
      }
    }
  end

  let(:file3) do
    {
      'version' => 1,
      'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
      'filename' => '00002.html',
      'label' => '00002.html',
      'hasMimeType' => 'text/html',
      'size' => 1914,
      'administrative' => {
        'sdrPreserve' => true,
        'shelve' => false
      },
      'access' => {
        'access' => 'world'
      }
    }
  end

  let(:file4) do
    {
      'version' => 1,
      'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
      'filename' => '00002.jp2',
      'label' => '00002.jp2',
      'hasMimeType' => 'image/jp2',
      'size' => 111467,
      'administrative' => {
        'sdrPreserve' => true,
        'shelve' => true
      },
      'access' => {
        'access' => 'world'
      }
    }
  end

  let(:filesets) do
    [
      {
        'version' => 1,
        'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
        'label' => 'Page 1',
        'structural' => { 'contains' => [file1, file2] }
      },
      {
        'version' => 1,
        'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
        'label' => 'Page 2',
        'structural' => { 'contains' => [file3, file4] }
      }
    ]
  end

  let(:data) do
    <<~JSON
      { "type":"#{object_type}",
        "label":"The object label","version":1,"access":{},
        "administrative":{"releaseTags":[],"hasAdminPolicy":"druid:dd999df4567"},
        "description":{"title":[{"primary":true,"titleFull":"the object title"}]},
        "identification":{},"structural":{"contains":#{filesets.to_json}}}
    JSON
  end

  context 'with a book' do
    let(:object_type) { Cocina::Models::Vocab.book }

    it 'generates contentMetadata.xml' do
      expect(generate).to be_equivalent_to '<?xml version="1.0"?>
         <contentMetadata objectId="druid:bc123de5678" type="book">
           <resource id="bc123de5678_1" sequence="1" type="page">
             <label>Page 1</label>
             <file id="00001.html" mimetype="text/html" size="997" preserve="yes" publish="no" shelve="no" role="transcription">
               <checksum type="sha1">cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7</checksum>
               <checksum type="md5">e6d52da47a5ade91ae31227b978fb023</checksum>
             </file>
             <file id="00001.jp2" mimetype="image/jp2" size="149570" preserve="yes" publish="yes" shelve="yes"/>
           </resource>
           <resource id="bc123de5678_2" sequence="2" type="page">
             <label>Page 2</label>
             <file id="00002.html" mimetype="text/html" size="1914" preserve="yes" publish="yes" shelve="no"/>
             <file id="00002.jp2" mimetype="image/jp2" size="111467" preserve="yes" publish="yes" shelve="yes"/>
           </resource>
         </contentMetadata>'
    end
  end

  context 'with an image' do
    let(:object_type) { Cocina::Models::Vocab.image }

    it 'generates contentMetadata.xml' do
      expect(generate).to be_equivalent_to '<?xml version="1.0"?>
         <contentMetadata objectId="druid:bc123de5678" type="image">
           <resource id="bc123de5678_1" sequence="1" type="image">
             <label>Page 1</label>
             <file id="00001.html" mimetype="text/html" size="997" preserve="yes" publish="no" shelve="no" role="transcription">
               <checksum type="sha1">cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7</checksum>
               <checksum type="md5">e6d52da47a5ade91ae31227b978fb023</checksum>
             </file>
             <file id="00001.jp2" mimetype="image/jp2"  size="149570" preserve="yes" publish="yes" shelve="yes"/>
           </resource>
           <resource id="bc123de5678_2" sequence="2" type="image">
             <label>Page 2</label>
             <file id="00002.html" mimetype="text/html" size="1914" preserve="yes" publish="yes" shelve="no"/>
             <file id="00002.jp2" mimetype="image/jp2" size="111467" preserve="yes" publish="yes" shelve="yes"/>
           </resource>
         </contentMetadata>'
    end
  end
end
