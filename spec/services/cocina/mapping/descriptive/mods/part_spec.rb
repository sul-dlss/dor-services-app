# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS part <--> cocina mappings' do
  describe 'isReferencedBy relatedItem/part (510c)' do
    # Adapted from kf840zn4567
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Alden, J.E. European Americana,</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number>635/94</number>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Alden, J.E. European Americana</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number>635/94</number>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      # Strip trailing comma or period from title. Technically author should be in contributor property
      # (or the string in a citation/reference note), but that can't be determined from the source data.
      # Any <detail type="part" should map to note.type "location within source" regardless of
      # relatedItem type or whether the part element is nested under relatedItem. Other values of
      # detail[@type] should map to note.type following the COCINA type vocabulary documentation.

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'referenced by',
              title: [
                {
                  value: 'Alden, J.E. European Americana'
                }
              ],
              note: [
                {
                  value: '635/94',
                  type: 'location within source'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'constituent relatedItem/part' do
    # Adapted from vt758zn6912
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <relatedItem type="constituent">
            <titleInfo>
              <title>[Unidentified sextet]</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>02:T00:04:01</number>
                <caption>Marker</caption>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo>
              <title>Steal Away</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>03:T00:08:35</number>
                <caption>Marker</caption>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="constituent">
            <titleInfo>
              <title>Railroad Porter Blues</title>
            </titleInfo>
            <part>
              <detail type="marker">
                <number>04:T00:15:35</number>
                <caption>Marker</caption>
              </detail>
            </part>
          </relatedItem>
        XML
      end

      let(:cocina) do
        {
          relatedResource: [
            {
              type: 'has part',
              title: [
                {
                  value: '[Unidentified sextet]'
                }
              ],
              note: [
                {
                  type: 'marker',
                  value: '02:T00:04:01',
                  displayLabel: 'Marker'
                }
              ]
            },
            {
              type: 'has part',
              title: [
                {
                  value: 'Steal Away'
                }
              ],
              note: [
                {
                  type: 'marker',
                  value: '03:T00:08:35',
                  displayLabel: 'Marker'
                }
              ]
            },
            {
              type: 'has part',
              title: [
                {
                  value: 'Railroad Porter Blues'
                }
              ],
              note: [
                {
                  type: 'marker',
                  value: '04:T00:15:35',
                  displayLabel: 'Marker'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Monolingual part with all subelements' do
    # valid MODS, but Arcadia will not map unless it shows up in our data.
    xit 'not mapped (to cocina) unless it shows up in our data'

    let(:mods) do
      <<~XML
        <part type="article" order="1">
          <detail type="section">
            <number>Section 1</number>
            <caption>This is the first section.</caption>
            <title>A Section</title>
          </detail>
          <extent unit="pages">
            <start>4</start>
            <end>9</end>
            <total>6</total>
            <list>pages 4-9<list>
          </extent>
          <date encoding="w3cdtf" keyDate="true" qualifier="approximate" calendar="Gregorian" point="start">2020-11</date>
          <text type="summary" displayLabel="Abstract">Here is some more info about what this article is about.</text>
        </part>
      XML
    end
  end

  describe 'Multilingual part' do
    # valid MODS, but Arcadia will not map unless it shows up in our data.
    xit 'not mapped (to cocina) unless it shows up in our data'

    # Every text element plus part, other than extent/total, can have the lang, script, and transliteration attributes.
    # The altRepGroup attribute appears only on the part element.
    let(:mods) do
      <<~XML
        <part type="article" order="1" altRepGroup="1" lang="eng" script="Latn">
          <detail>
            <title>This is a title in English</title>
          </detail>
        </part>
        <part type="article" altRepGroup="1" lang="rus" script="Cyrl" transliteraion = "ALA/LC Romanization Tables">
          <detail>
            <title>Pretend this is the same title in Russian</title>
          </detail>
        </part>
      XML
    end
  end

  describe 'Hierarchical detail' do
    # valid MODS, but Arcadia will not map unless it shows up in our data.
    xit 'not mapped (to cocina) unless it shows up in our data'

    let(:mods) do
      <<~XML
        <part>
          <detail type="volume" level="0">
            <title>Some animals</title>
          </detail>
          <detail type="chapter" level="1">
            <title>Chapter 1: Mammals</title>
          </detail>
          <detail> type="section" level="2">
            <caption>This section is about cats.</caption>
          </detail>
          <detail type="section" level="2">
            <caption>This section is about rabbits.</caption>
          </detail>
          <detail type="chapter" level="1">
            <title>Chapter 2: Amphibians</title>
          </detail>
          <detail type="section" level="2">
            <caption>This section is about salamanders.</caption>
          </detail>
          <detail type="section" level="2">
            <caption>This section is about frogs.</caption>
          </detail>
        </part>
      XML
    end
  end

  describe 'Multiple ordered parts' do
    # valid MODS, but Arcadia will not map unless they show up in our data.
    xit 'not mapped (to cocina) unless they show up in our data'

    let(:mods) do
      <<~XML
        <part type="volume" order="1">
          <detail>
            <title>A-L</title>
            <number>Volume 1</number>
            <caption>It's about some stuff.</caption>
          </detail>
        </part>
        <part type="volume" order="2">
          <detail>
            <title>M-Z</title>
            <number>Volume 2</number>
            <caption>It's about some other stuff.</caption>
          </detail>
        <part>
      XML
    end
  end
end
