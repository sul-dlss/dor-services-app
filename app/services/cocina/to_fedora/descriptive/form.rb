# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps forms from cocina to MODS XML
      class Form
        # @params [Nokogiri::XML::Builder] xml
        # @params [Array<Cocina::Models::DescriptiveValue>] forms
        def self.write(xml:, forms:)
          new(xml: xml, forms: forms).write
        end

        def initialize(xml:, forms:)
          @xml = xml
          @forms = forms
        end

        def write
          Array(forms).each_with_index do |form, _alt_rep_group|
            write_basic(form)
          end
        end

        private

        attr_reader :xml, :forms

        def write_basic(form)
          attributes = {}
          attributes[:displayLabel] = form.displayLabel if form.displayLabel
          case form.type
          when 'resource type'
            xml.typeOfResource form.value, attributes
          when 'map scale', 'map projection'
            # do nothing, these end up in subject/cartographics
          when 'genre'
            xml.genre form.value, with_uri_info(form, attributes)
          else
            xml.genre form.value, with_uri_info(form, attributes.merge(type: form.type))
          end
        end

        def with_uri_info(cocina, xml_attrs)
          xml_attrs[:valueURI] = cocina.uri
          xml_attrs[:authorityURI] = cocina.source&.uri
          xml_attrs[:authority] = cocina.source&.code
          xml_attrs.compact
        end
      end
    end
  end
end
