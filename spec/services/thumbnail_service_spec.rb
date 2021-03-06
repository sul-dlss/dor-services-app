# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailService do
  let(:instance) { described_class.new(object) }

  describe '#thumb' do
    subject { instance.thumb }

    context 'for a collection' do
      let(:object) { instantiate_fixture('druid:bc123df4567', Dor::Collection) }

      it 'returns nil if there is no contentMetadata datastream' do
        expect(subject).to be_nil
      end
    end

    context 'for an item' do
      let(:object) { instantiate_fixture('druid:bc123df4567', Dor::Item) }

      it 'returns nil if there is no contentMetadata' do
        object.contentMetadata.content = '<contentMetadata/>'
        expect(subject).to be_nil
      end

      it 'finds the first image as the thumb when no specific thumbs are specified' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="image">
            <resource id="0001" sequence="1" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_05_0001.jp2')
      end

      it 'finds a thumb resource marked as thumb with the thumb attribute first, even if it is listed second' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="map">
            <resource id="0001" sequence="1" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="thumb">
              <file id="bc123df4567_thumb.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_thumb.jp2')
      end

      it 'finds a thumb resource marked as thumb without the thumb attribute first, even if it is listed second when there are no other thumbs specified' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="map">
            <resource id="0001" sequence="1" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" type="thumb">
              <file id="bc123df4567_thumb.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_thumb.jp2')
      end

      it 'finds a thumb resource marked as thumb with the thumb attribute first, even if it is listed second and there is another image marked as thumb first' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="map">
            <resource id="0001" sequence="1" thumb="yes" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="thumb">
              <file id="bc123df4567_thumb.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_thumb.jp2')
      end

      it 'finds an image resource marked as thumb with the thumb attribute when there is no resource thumb specified' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="map">
            <resource id="0001" sequence="1" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="image">
              <file id="bc123df4567_05_0002.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_05_0002.jp2')
      end

      it 'finds an image resource marked as thumb with the thumb attribute when there is a resource thumb specified but not the thumb attribute' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="book">
            <resource id="0001" sequence="1" type="thumb">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="image">
              <file id="bc123df4567_05_0002.jp2" mimetype="image/jp2"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_05_0002.jp2')
      end

      it 'finds a page resource marked as thumb with the thumb attribute when there is a resource thumb specified but not the thumb attribute' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="file">
            <resource id="0001" sequence="1" type="thumb">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
              <file id="extra_ignored_image" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="page">
              <file id="bc123df4567_05_0002.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0003" sequence="3" type="page">
              <externalFile fileId="2542A.jp2" mimetype="image/jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1">
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('bc123df4567/bc123df4567_05_0002.jp2')
      end

      it 'finds an externalFile image resource when there are no other images' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="file">
            <resource id="0001" sequence="1" type="file">
              <file id="bc123df4567_05_0001.pdf" mimetype="file/pdf"/>
            </resource>
            <resource id="0002" sequence="2" type="image">
              <externalFile fileId="2542A.jp2" mimetype="image/jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1">
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('cg767mn6478/2542A.jp2')
      end

      it 'finds an externalFile page resource when there are no other images, even if objectId attribute is missing druid prefix' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="file">
            <resource id="0001" sequence="1" type="file">
              <file id="bc123df4567_05_0001.pdf" mimetype="file/pdf"/>
            </resource>
            <resource id="0002" sequence="2" type="page">
              <externalFile fileId="2542A.jp2" mimetype="image/jp2" objectId="cg767mn6478" resourceId="cg767mn6478_1">
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('cg767mn6478/2542A.jp2')
      end

      it 'finds an explicit externalFile thumb resource before another image resource, and encode the space' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="file">
            <resource id="0001" sequence="1" type="image">
              <file id="bc123df4567_05_0001.jp2" mimetype="image/jp2"/>
            </resource>
            <resource id="0002" sequence="2" thumb="yes" type="page">
              <externalFile fileId="2542A withspace.jp2" mimetype="image/jp2" objectId="druid:cg767mn6478" resourceId="cg767mn6478_1">
            </resource>
          </contentMetadata>
        XML
        expect(subject).to eq('cg767mn6478/2542A withspace.jp2')
      end

      it 'returns nil if no thumb is identified' do
        object.contentMetadata.content = <<-XML
          <?xml version="1.0"?>
          <contentMetadata objectId="druid:bc123df4567" type="file">
            <resource id="0001" sequence="1" type="file">
              <file id="some_file.pdf" mimetype="file/pdf"/>
            </resource>
          </contentMetadata>
        XML
        expect(subject).to be_nil
      end

      it 'returns nil if there is no contentMetadata datastream at all' do
        object.datastreams['contentMetadata'] = nil
        expect(subject).to be_nil
      end
    end
  end
end
