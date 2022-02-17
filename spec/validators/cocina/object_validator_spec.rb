# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ObjectValidator do
  let(:unique_source_id_validator) { instance_double(Cocina::UniqueSourceIdValidator, valid?: true) }
  let(:validate_dark_service) { instance_double(Cocina::ValidateDarkService, valid?: true) }
  let(:apo_existence_validator) { instance_double(Cocina::ApoExistenceValidator, valid?: true) }
  let(:collection_existence_validator) { instance_double(Cocina::CollectionExistenceValidator, valid?: true) }

  before do
    allow(Cocina::UniqueSourceIdValidator).to receive(:new).and_return(unique_source_id_validator)
    allow(Cocina::ValidateDarkService).to receive(:new).and_return(validate_dark_service)
    allow(Cocina::ApoExistenceValidator).to receive(:new).and_return(apo_existence_validator)
    allow(Cocina::CollectionExistenceValidator).to receive(:new).and_return(collection_existence_validator)
  end

  context 'when a request DRO' do
    let(:cocina_object) { instance_double(Cocina::Models::RequestDRO, dro?: true) }

    it 'validates' do
      described_class.validate(cocina_object)

      expect(unique_source_id_validator).to have_received(:valid?)
      expect(validate_dark_service).to have_received(:valid?)
      expect(apo_existence_validator).to have_received(:valid?)
      expect(collection_existence_validator).to have_received(:valid?)
    end
  end

  context 'when a DRO' do
    let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true, externalIdentifier: nil) }

    it 'validates' do
      described_class.validate(cocina_object)

      expect(unique_source_id_validator).not_to have_received(:valid?)
      expect(validate_dark_service).to have_received(:valid?)
      expect(apo_existence_validator).to have_received(:valid?)
      expect(collection_existence_validator).to have_received(:valid?)
    end
  end

  context 'when a Collection' do
    let(:cocina_object) { instance_double(Cocina::Models::Collection, dro?: false, externalIdentifier: nil) }

    it 'validates' do
      described_class.validate(cocina_object)

      expect(unique_source_id_validator).not_to have_received(:valid?)
      expect(validate_dark_service).to have_received(:valid?)
      expect(apo_existence_validator).to have_received(:valid?)
      expect(collection_existence_validator).not_to have_received(:valid?)
    end
  end
end
