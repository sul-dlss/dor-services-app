# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS accessCondition <--> cocina mappings' do
  describe 'Restriction on access type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                value: 'Available to Stanford researchers only.',
                type: 'access restriction'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Restriction on access type without spaces' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition type="restrictionOnAccess">Available to Stanford researchers only.</accessCondition>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                value: 'Available to Stanford researchers only.',
                type: 'access restriction'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Restrictions on access type without spaces' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition type="restrictionsOnAccess">Available to Stanford researchers only.</accessCondition>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                value: 'Available to Stanford researchers only.',
                type: 'access restriction'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Restriction on use and reproduction type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition type="use and reproduction">User agrees that, where applicable, blah blah.</accessCondition>
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                value: 'User agrees that, where applicable, blah blah.',
                type: 'use and reproduction'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Restriction on use and reproduction type without spaces' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition type="useAndReproduction">User agrees that, where applicable, blah blah.</accessCondition>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <accessCondition type="use and reproduction">User agrees that, where applicable, blah blah.</accessCondition>
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                value: 'User agrees that, where applicable, blah blah.',
                type: 'use and reproduction'
              }
            ]
          }
        }
      end
    end
  end

  describe 'License' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition type="license">CC by: CC BY Attribution</accessCondition>
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                value: 'CC by: CC BY Attribution',
                type: 'license'
              }
            ]
          }
        }
      end
    end
  end

  describe 'Link to external value only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <accessCondition xlink:href="http://accesscondition.org/accesscondition" />
        XML
      end

      let(:cocina) do
        {
          access: {
            note: [
              {
                valueAt: 'http://accesscondition.org/accesscondition'
              }
            ]
          }
        }
      end
    end
  end
end
