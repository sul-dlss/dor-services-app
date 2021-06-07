# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::AccessConditions do
  subject(:access) { described_class.new(public_mods: public_mods, rights_md: Dor::RightsMetadataDS.from_xml(rights_md)) }

  let(:mods) do
    <<~XML
      <mods:mods xmlns:mods="http://www.loc.gov/mods/v3">
        <mods:titleInfo>
            <mods:title type="main">Some Excellent Title</mods:title>
        </mods:titleInfo>
      </mods:mods>
    XML
  end
  let(:public_mods) { Dor::DescMetadataDS.from_xml(mods).ng_xml }

  before { allow(Honeybadger).to receive(:notify) }

  describe '#add' do
    context 'when special NONE license url' do
      let(:rights_md) do
        <<~XML
          <rightsMetadata>
            <use>
              <machine type="creativeCommons">none</machine>
            </use>
          </rightsMetadata>
        XML
      end

      it 'does not alert HB and does not add a license to public mods' do
        access.add
        expect(public_mods.xpath('//mods:accessCondition[@type="license"]').size).to eq 0
        expect(Honeybadger).not_to have_received(:notify)
      end
    end

    context 'when bogus license url' do
      let(:rights_md) do
        <<~XML
          <rightsMetadata>
            <use>
              <license>https://some.unknown.license</license>
            </use>
          </rightsMetadata>
        XML
      end

      it 'alerts HB and does not add a license to public mods' do
        access.add
        expect(public_mods.xpath('//mods:accessCondition[@type="license"]').size).to eq 0
        expect(Honeybadger).to have_received(:notify)
      end
    end

    context 'when known license url that maps' do
      let(:rights_md) do
        <<~XML
          <rightsMetadata>
            <use>
              <license>https://www.gnu.org/licenses/agpl.txt</license>
            </use>
          </rightsMetadata>
        XML
      end

      it 'does not alert HB and adds a license to public mods' do
        access.add
        expect(public_mods.xpath('//mods:accessCondition[@type="license"]').text).to eq 'AGPL-3.0-only GNU Affero General Public License'
        expect(Honeybadger).not_to have_received(:notify)
      end
    end

    context 'when we do not have a license url' do
      let(:rights_md) do
        <<~XML
          <rightsMetadata>
            <use>
              <nada>no license url here</nada>
            </use>
          </rightsMetadata>
        XML
      end

      it 'does not alert HB and does not add a license to public mods' do
        expect(public_mods.xpath('//mods:accessCondition[@type="license"]').size).to eq 0
        expect(Honeybadger).not_to have_received(:notify)
      end
    end
  end
end
