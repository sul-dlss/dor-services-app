# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::PublicCocinaService do
  subject(:json) { JSON.parse(create) }

  let(:create) { described_class.create(fedora_obj) }

  let(:fedora_obj) do
    Dor::Item.new(
      pid: 'druid:hz651dj0129',
      source_id: 'sul:50807230',
      label: 'Census of India 1931',
      admin_policy_object_id: 'druid:xk494bv8475'
    ).tap do |i|
      i.descMetadata.mods_title = 'Census of India, 1931'
      i.contentMetadata.content = content_metadata
    end
  end

  let(:content_metadata) do
    <<~XML
      <contentMetadata objectId="hz651dj0129" type="book">
        <resource id="hz651dj0129_1" sequence="1" type="page">
          <label>Page 1</label>
          <file id="50807230_0001.tif" mimetype="image/tiff" size="56987913" preserve="yes" publish="no" shelve="no">
            <checksum type="md5">6618d3d35e6adbc5625405cd244f6bda</checksum>
            <checksum type="sha1">4af78fde7fd8099ac7e3fee3a58332b1d268d244</checksum>
            <imageData width="3544" height="5360"/>
          </file>
          <file id="50807230_0001.jp2" mimetype="image/jp2" size="3575822" preserve="no" publish="no" shelve="no">
            <checksum type="md5">c99fae3c4c53e40824e710440f08acb9</checksum>
            <checksum type="sha1">0a089200032d209e9b3e7f7768dd35323a863fcc</checksum>
            <imageData width="3544" height="5360"/>
          </file>
        </resource>
        <resource id="hz651dj0129_2" sequence="2" type="page">
          <label>Page 2</label>
          <file id="50807230_0002.tif" mimetype="image/tiff" size="31525443" preserve="yes" publish="no" shelve="no">
            <checksum type="md5">010f88d1e40a6f81badde34e00c4ab5d</checksum>
            <checksum type="sha1">46308444f201bec15857ac9338c2b6060f518ca5</checksum>
            <imageData width="5736" height="5496"/>
          </file>
          <file id="50807230_0002.jp2" mimetype="image/jp2" size="5920056" preserve="no" publish="yes" shelve="yes">
            <checksum type="md5">08544fe844c45eebb552f280709af564</checksum>
            <checksum type="sha1">4691466371691f774151574d1cf97ed73ba45d2c</checksum>
            <imageData width="5736" height="5496"/>
          </file>
        </resource>
        <resource id="hz651dj0129_3" sequence="3" type="page">
          <label>Page 3</label>
          <file id="50807230_0003.tif" mimetype="image/tiff" size="31525443" preserve="yes" publish="no" shelve="no">
            <checksum type="md5">0b43cedb0c8beb030e7c0e87a7ae46ae</checksum>
            <checksum type="sha1">6b1fc3618c2c195ccc99432491e3a864b2df02af</checksum>
            <imageData width="5736" height="5496"/>
          </file>
          <file id="50807230_0003.jp2" mimetype="image/jp2" size="5920374" preserve="no" publish="yes" shelve="yes">
            <checksum type="md5">a9acee40e54bc6da6cee1388f7cc33e9</checksum>
            <checksum type="sha1">9c62ab0930a8e3540b7c151c3e52e8b7732e9c2e</checksum>
            <imageData width="5736" height="5496"/>
          </file>
        </resource>
      </contentMetadata>
    XML
  end

  it 'discards the non-published filesets and files' do
    expect(json.dig('structural', 'contains').size).to eq 2
    expect(json.dig('structural', 'contains', 1, 'structural', 'contains').size).to eq 1
    expect(json.dig('structural', 'contains', 1, 'structural', 'contains', 0, 'filename')).to eq '50807230_0003.jp2'
  end
end
