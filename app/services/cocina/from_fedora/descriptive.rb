# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        { title: [{ status: 'primary', value: TitleMapper.build(item) }] }.tap do |desc|
          desc[:note] = notes if notes.present?
          desc[:language] = language if language.present?
          desc[:contributor] = contributor if contributor.present?
          desc[:form] = form if form.present?
        end
      end

      private

      attr_reader :item

      def notes
        @notes ||= [].tap do |items|
          items << original_url if original_url
          items << abstract if abstract
          items << statement_of_responsibility if statement_of_responsibility
          items << thesis_statement if thesis_statement
          additional_notes.each do |note|
            items << { value: note.content }
          end
        end
      end

      def abstract
        return if item.descMetadata.abstract.blank?

        @abstract ||= { type: 'summary', value: item.descMetadata.abstract.first }
      end

      # TODO: Figure out how to encode displayLabel https://github.com/sul-dlss/dor-services-app/issues/849#issuecomment-635713964
      def original_url
        val = item.descMetadata.ng_xml.xpath('//mods:note[@type="system details"][@displayLabel="Original site"]', mods: DESC_METADATA_NS).first
        { type: 'system details', value: val.content } if val
      end

      def statement_of_responsibility
        val = item.descMetadata.ng_xml.xpath('//mods:note[@type="statement of responsibility"]', mods: DESC_METADATA_NS).first
        { type: 'statement of responsibility', value: val.content } if val
      end

      def thesis_statement
        val = item.descMetadata.ng_xml.xpath('//mods:note[@type="thesis"]', mods: DESC_METADATA_NS).first
        { type: 'thesis', value: val.content } if val
      end

      # Returns any notes values that do not include a type attribute
      def additional_notes
        item.descMetadata.ng_xml.xpath('//mods:note[not(@type)]', mods: DESC_METADATA_NS)
      end

      def language
        @language ||= [].tap do |langs|
          item.descMetadata.ng_xml.xpath('//mods:language', mods: DESC_METADATA_NS).each do |lang|
            language_hash = {}
            val = lang.xpath('./mods:languageTerm[@type="text"]', mods: DESC_METADATA_NS).first
            code = lang.xpath('./mods:languageTerm[@type="code"]', mods: DESC_METADATA_NS).first

            language_hash = {
              value: val.content,
              uri: val.attribute('valueURI').value,
              source: {
                uri: val.attribute('authorityURI').value
              }
            } if val.present?

            language_hash = {
              code: code.content,
              source: {
                code: code.attribute('authority').value
              }
            } if code.present?

            langs << language_hash unless language_hash.empty?
          end
        end
      end

      def contributor
        @contributor ||= [].tap do |names|
          item.descMetadata.ng_xml.xpath('//mods:name', mods: DESC_METADATA_NS).each do |name|
            name_part = name.xpath('./mods:namePart', mods: DESC_METADATA_NS).first
            role_hash = {}
            name.xpath('./mods:role/mods:roleTerm', mods: DESC_METADATA_NS).each do |role_term|
              if role_term.attribute('type').value.include? 'code'
                role_hash[:code] = role_term.content 
                role_hash[:source] = { code: role_term.attribute('authority').value }
              end
              role_hash[:value] = role_term.content if role_term.attribute('type').value.include? 'text'
            end
            type = name.attribute('type')
            usage = name.attribute('usage')
            name_hash = { name: { value: name_part.content }, type: type.value }
            name_hash[:status] = usage.value if usage.present?
            name_hash[:role] = [role_hash] unless role_hash.empty?
            names << name_hash
          end
        end
      end

      def form
        # TODO: Enchance for ETD form data
        @form ||= [].tap do |forms|
          item.descMetadata.ng_xml.xpath('//mods:physicalDescription', mods: DESC_METADATA_NS).each do |form_data|
            form_data.xpath('./mods:form', mods: DESC_METADATA_NS).each do |form_content|
              source = form_content.attribute('authority').value
              forms << { value: form_content.content, source: { code: source } }
            end

            form_data.xpath('./mods:extent', mods: DESC_METADATA_NS).each do |extent|
              forms << { value: extent.content, type: 'extent' }
            end
          end
        end
      end
    end
  end
end
