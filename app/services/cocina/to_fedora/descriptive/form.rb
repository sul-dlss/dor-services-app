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
          xml.typeOfResource form.value, attributes if form.type == 'resource type'
        end
      end
    end
  end
end
