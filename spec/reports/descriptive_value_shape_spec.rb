# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptiveValueShape do
  describe 'countable?' do
  # a cocina DescriptiveBasicValue is countable if it has:
  #  - a child property of "value", "uri" or "valueAt" with a non-blank value (all of these are Strings or Integers)
  #  - a child property of "structuredValue", "parallelValue" or "groupedValue"
  #      with a child or descendent property of "value" or "uri" with a non-blank value BUT
  #      the descendent path can only have "structuredValue" or "parallelValue" between it and the child with the value
    context 'with a DescriptiveBasicValue or a treat-alike' do
      let(:descriptive_value_with_uri) { { "uri": "https://id.loc.gov/authorities/names/n79081538" } }
      let(:descriptive_value_with_value) { { "value": "i am the value of a value" } }
      let(:descriptive_value_with_value_at) { { "valueAt": "https://id.loc.gov/authorities/names/n79081538" } }
      let(:descriptive_value_not_countable) { { "displayLabel": "stuff" } }

      context 'when "value" property present' do
        it 'true when property has value' do
          expect(described_class.new({}).send(:countable?, descriptive_value_with_value)).to be_truthy
        end

        it 'false when no property value' do
          expect(described_class.new({}).send(:countable?, { "value": "" })).to be_falsey
        end
      end

      context 'when "uri" property present' do
        it 'true when property has value' do
          expect(described_class.new({}).send(:countable?, descriptive_value_with_uri)).to be_truthy
        end

        it 'false when no property value' do
          expect(described_class.new({}).send(:countable?, { "uri": "" })).to be_truthy
        end
      end

      context 'when "valueAt" property present' do
        it 'true when property has value' do
          expect(described_class.new({}).send(:countable?, descriptive_value_with_value_at)).to be_truthy
        end

        it 'false when no property value' do
          expect(described_class.new({}).send(:countable?, { "valueAt": "" })).to be_truthy
        end
      end

      it 'true when multiple key properties are present' do
        expect(described_class.new({}).send(:countable?, descriptive_value_with_uri.merge(descriptive_value_with_value))).to be_truthy
      end

      it 'false when no countable value is present' do
        expect(described_class.new({}).send(:countable?, descriptive_value_not_countable)).to be_falsey
      end
    end

    it 'false when object is not a Hash' do
      expect(described_class.new({}).send(:countable?, 'not a hash')).to be_falsey
      expect(described_class.new({}).send(:countable?, ['not a hash'])).to be_falsey
    end

    context 'with a parallelValue' do
      let(:simple_parallel_value) do
        {
          parallelValue: [
            {
              value: 'The master and Margarita'
            },
            {
              value: 'Мастер и Маргарита'
            }
          ],
          type: 'title'
        }
      end

      it 'true when there are values' do
        expect(described_class.new({}).send(:countable?, simple_parallel_value)).to be_truthy
      end
    end

    context 'with a structuredValue' do
      context 'with values' do
        let(:nested_structured_value) do
          {
            structuredValue: [
              {
                structuredValue: [
                  {
                    value: 'brisk junket',
                    type: 'main title'
                  },
                  {
                    value: 'ti1:nonSort',
                    type: 'nonsorting characters'
                  }
                ]
              }
            ],
            type: 'title'
          }
        end

        it 'true' do
          expect(described_class.new({}).send(:countable?, nested_structured_value)).to be_truthy
        end
      end

      context 'without values' do
        let(:nested_structured_value) do
          {
            structuredValue: [
              {
                structuredValue: [
                  {
                    type: 'main title'
                  },
                  {
                    value: '',
                    type: 'nonsorting characters'
                  }
                ]
              }
            ],
            type: 'title'
          }
        end

        it 'false' do
          expect(described_class.new({}).send(:countable?, nested_structured_value)).to be_falsey
        end
      end


    end

    context 'with a groupedValue' do
      let(:grouped_value) do
        {
          groupedValue: [
            {
              value: 'Strachey, Dorothy',
              type: 'name'
            },
            {
              value: 'Olivia',
              type: 'pseudonym'
            }
          ]
        }
      end

      it 'true when there are values' do
        expect(described_class.new({}).send(:countable?, grouped_value)).to be_truthy
      end
    end
  end
end
