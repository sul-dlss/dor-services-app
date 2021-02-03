# frozen_string_literal: true

MODS_ATTRIBUTES = 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" version="3.7"
    xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd"'

RSpec.shared_examples 'cocina to MODS' do |expected_xml|
  subject(:xml) { writer.to_xml }

  # writer object is declared in the context of calling examples

  let(:mods_attributes) do
    {
      'xmlns' => 'http://www.loc.gov/mods/v3',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'version' => '3.6',
      'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd'
    }
  end

  it 'builds the expected xml' do
    expect(xml).to be_equivalent_to <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{expected_xml}
      </mods>
    XML
  end
end

# When starting from MODS.
RSpec.shared_examples 'MODS cocina mapping' do
  # Required: mods, cocina
  # Optional: druid, roundtrip_mods, warnings, errors

  # Note that this instantiation of Description does NOT validate against OpenAPI due to title validation issues.
  let(:orig_cocina_description) { Cocina::Models::Description.new(cocina, false, false) }

  let(:orig_mods_ng) { ng_mods_for(mods) }

  let(:roundtrip_mods_ng) { defined?(roundtrip_mods) ? ng_mods_for(roundtrip_mods) : nil }

  let(:local_druid) { defined?(druid) ? druid : 'no-druid-given' }

  let(:local_warnings) { defined?(warnings) ? warnings : [] }

  let(:local_errors) { defined?(errors) ? errors : [] }

  context 'when mapping from MODS (to cocina)' do
    let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

    let(:actual_cocina_props) { Cocina::FromFedora::Descriptive.props(mods: orig_mods_ng, druid: local_druid, notifier: notifier) }

    before do
      allow(notifier).to receive(:warn)
      allow(notifier).to receive(:error)
    end

    it 'mods snippet(s) produce valid MODS' do
      expect { orig_mods_ng }.not_to raise_error
      expect { roundtrip_mods_ng }.not_to raise_error
    end

    it 'cocina hash produces valid cocina Description' do
      # TODO: support testing with no title
      cocina_props = actual_cocina_props.deep_dup
      cocina_props[:title] = [{ value: 'Test title' }] if cocina_props[:title].nil?
      expect { Cocina::Models::Description.new(cocina_props) }.not_to raise_error
    end

    it 'MODS maps to expected cocina' do
      expect(actual_cocina_props).to be_deep_equal(cocina)
    end

    it 'notifier receives warning and/or error messages as specified' do
      # TODO: support testing with no title
      Cocina::FromFedora::Descriptive.props(mods: orig_mods_ng, druid: local_druid, notifier: notifier, title_builder: TestTitleBuilder)
      if local_warnings.empty?
        expect(notifier).not_to have_received(:warn)
      else
        local_warnings.each do |warning|
          if warning.context
            expect(notifier).to have_received(:warn).with(warning.msg, warning.context).exactly(warning.times || 1).times
          else
            expect(notifier).to have_received(:warn).with(warning.msg).exactly(warning.times || 1).times
          end
        end
      end

      if local_errors.empty?
        expect(notifier).not_to have_received(:error)
      else
        local_errors.each do |error|
          if error.context
            expect(notifier).to have_received(:error).with(error.msg, error.context).exactly(error.times || 1).times
          else
            expect(notifier).to have_received(:error).with(error.msg).exactly(error.times || 1).times
          end
        end
      end
    end
  end

  # Checks mapping from roundtripped MODS back to cocina.
  context 'when roundtrip mapping from MODS (to cocina)' do
    let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

    let(:actual_cocina_props) { Cocina::FromFedora::Descriptive.props(mods: roundtrip_mods_ng, druid: local_druid, notifier: notifier) }

    before do
      allow(notifier).to receive(:warn)
      allow(notifier).to receive(:error)
    end

    it 'MODS maps to expected cocina' do
      expect(actual_cocina_props).to be_deep_equal(cocina) if defined?(roundtrip_mods)
    end
  end

  context 'when mapping to MODS (from cocina)' do
    let(:expected_mods_ng) { roundtrip_mods_ng || orig_mods_ng }

    let(:actual_mods_ng) { Cocina::ToFedora::Descriptive.transform(orig_cocina_description, local_druid).doc }

    let(:actual_xml) { actual_mods_ng.to_xml }

    it 'cocina Description maps to expected MODS' do
      expect(actual_xml).to be_equivalent_to expected_mods_ng.to_xml
    end

    it 'cocina Description maps to normalized MODS' do
      # the starting MODS is normalized to address discrepancies found against MODS roundtripped to data store (Fedora)
      #  and back, per Arcadia's specifications.  E.g., removal of empty nodes and attributes; addition of eventType to
      #  originInfo nodes.
      expect(actual_xml).to be_equivalent_to Cocina::ModsNormalizer.normalize(mods_ng_xml: orig_mods_ng, druid: local_druid)
    end
  end
end

# When starting from cocina, e.g., H2.
RSpec.shared_examples 'cocina MODS mapping' do
  # Required: mods, cocina
  # Optional: druid, roundtrip_cocina, warnings, errors

  # Note that this instantiation of Description does NOT validate against OpenAPI due to title validation issues.
  let(:orig_cocina_description) { Cocina::Models::Description.new(cocina, false, false) }

  let(:mods_ng) { ng_mods_for(mods) }

  let(:local_druid) { defined?(druid) ? druid : 'no-druid-given' }

  let(:local_warnings) { defined?(warnings) ? warnings : [] }

  let(:local_errors) { defined?(errors) ? errors : [] }

  context 'when mapping from cocina (to MODS)' do
    let(:actual_mods_ng) { Cocina::ToFedora::Descriptive.transform(orig_cocina_description, local_druid).doc }

    let(:actual_xml) { actual_mods_ng.to_xml }

    it 'mods snippet(s) produce valid MODS' do
      expect { mods_ng }.not_to raise_error
    end

    it 'cocina Description maps to expected MODS' do
      expect(actual_xml).to be_equivalent_to mods_ng.to_xml
    end
  end

  context 'when mapping to cocina (from MODS)' do
    let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

    let(:actual_cocina_props) { Cocina::FromFedora::Descriptive.props(mods: mods_ng, druid: local_druid, notifier: notifier) }

    let(:expected_cocina) { defined?(roundtrip_cocina) ? roundtrip_cocina : cocina }

    before do
      allow(notifier).to receive(:warn)
      allow(notifier).to receive(:error)
    end

    it 'cocina hash produces valid cocina Description' do
      cocina_props = actual_cocina_props.deep_dup
      cocina_props[:title] = [{ value: 'Test title' }] if cocina_props[:title].nil?
      expect { Cocina::Models::Description.new(cocina_props) }.not_to raise_error
    end

    it 'MODS maps to expected cocina' do
      expect(actual_cocina_props).to eq(expected_cocina)
    end

    it 'notifier receives warning and/or error messages as specified' do
      Cocina::FromFedora::Descriptive.props(mods: mods_ng, druid: local_druid, notifier: notifier, title_builder: TestTitleBuilder)
      if local_warnings.empty?
        expect(notifier).not_to have_received(:warn)
      else
        local_warnings.each do |warning|
          if warning.context
            expect(notifier).to have_received(:warn).with(warning.msg, warning.context).exactly(warning.times || 1).times
          else
            expect(notifier).to have_received(:warn).with(warning.msg).exactly(warning.times || 1).times
          end
        end
      end

      if local_errors.empty?
        expect(notifier).not_to have_received(:error)
      else
        local_errors.each do |error|
          if error.context
            expect(notifier).to have_received(:error).with(error.msg, error.context).exactly(error.times || 1).times
          else
            expect(notifier).to have_received(:error).with(error.msg).exactly(error.times || 1).times
          end
        end
      end
    end
  end
end

def ng_mods_for(snippet)
  xml = <<~XML
    <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
      xmlns="http://www.loc.gov/mods/v3" version="3.7"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
      #{snippet}
    </mods>
  XML
  Nokogiri.XML(xml, nil, 'UTF-8', Nokogiri::XML::ParseOptions.new.strict)
end

Notification = Struct.new(:msg, :context, :times, keyword_init: true)

class TestTitleBuilder
  # @param [Nokogiri::XML::Element] resource_element mods or relatedItem element
  # @param [Cocina::FromFedora::DataErrorNotifier] notifier
  # @return [Hash] a hash that can be mapped to a cocina model
  def self.build(resource_element:, notifier:, require_title: nil)
    titles = resource_element.xpath('mods:titleInfo', mods: Dor::DescMetadataDS::MODS_NS)
    return [{ value: 'Placeholder title for specs' }] if titles.empty?
  end
end
