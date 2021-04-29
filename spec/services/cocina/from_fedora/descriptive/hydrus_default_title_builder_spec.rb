# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::HydrusDefaultTitleBuilder do
  let(:object) { Dor::Item.new }

  describe '.build' do
    subject(:build) { described_class.build(resource_element: ng_xml.root, require_title: true, notifier: notifier) }

    let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

    context 'when no title' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title />
            </titleInfo>
          </mods>
        XML
      end

      it 'returns Hydrus as title' do
        expect(build).to eq([{ value: 'Hydrus' }])
      end
    end

    context 'when relatedItem with no title' do
      let(:ng_xml) do
        Nokogiri::XML <<~XML
          <relatedItem xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.6"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title />
            </titleInfo>
          </mods>
        XML
      end

      before do
        allow(notifier).to receive(:error)
        allow(notifier).to receive(:warn)
      end

      it 'returns empty' do
        expect(build).to be_empty
        expect(notifier).not_to have_received(:warn)
        expect(notifier).not_to have_received(:error)
      end
    end
  end
end
