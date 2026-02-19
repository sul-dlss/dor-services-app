# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Title do
  describe '.build' do
    subject(:build) do
      described_class.build(marc:, notifier:)
    end

    let(:notifier) { instance_double(Cocina::Models::Mapping::ErrorNotifier) }
    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with no title fields' do
      let(:marc_hash) do
        {
          'fields' => [
            { 'xxx' => { 'subfields' => [{ 'a' => 'nothing' }] } }
          ]
        }
      end

      before do
        allow(notifier).to receive(:error)
        allow(notifier).to receive(:warn)
      end

      it 'returns empty and notifies error' do
        expect(build).to be_nil
        expect(notifier).to have_received(:error).with('Missing title')
      end
    end

    context 'with a 245a and no non-sorting (ind2)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '245' => { 'ind1' => '1', 'ind2' => '0',
                         'subfields' => [{ 'a' => 'Gaudy night /' }, { 'c' => 'by Dorothy L. Sayers' }] } }
          ]
        }
      end

      it 'returns the title' do
        expect(build).to eq([{ value: 'Gaudy night' }])
      end
    end

    context 'with a 245a and non-sorting (ind2) and no 880' do
      let(:marc_hash) do
        {
          'fields' => [
            { '245' => { 'ind1' => '1', 'ind2' => '4',
                         'subfields' => [{ 'a' => 'The unpleasantness at the Bellona Club.' }] } }
          ]
        }
      end

      it 'returns the title' do
        expect(build).to eq([
                              {
                                structuredValue: [
                                  { value: 'The', type: 'nonsorting characters' },
                                  { value: 'unpleasantness at the Bellona Club.', type: 'main title' }
                                ]
                              }
                            ])
      end
    end

    context 'with title with subtitle (245 abfgknps)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '245' => { 'ind1' => '1', 'ind2' => '4', 'subfields' => [
              { 'a' => 'The medium term expenditure framework (MTEF) for ... and the annual estimates for ...' },
              { 'n' => '016,' },
              { 'p' => 'Ministry of Tourism :' },
              { 'b' => 'expenditure to be met out of moneys granted and drawn from the consolidated fund, central government budget.' }
            ] } }
          ]
        }
      end

      it 'returns the title with structured value' do
        expect(build).to eq([
                              {
                                structuredValue: [
                                  { value: 'The', type: 'nonsorting characters' },
                                  {
                                    value: 'medium term expenditure framework (MTEF) for ... and the annual estimates for ...', type: 'main title'
                                  },
                                  {
                                    value: '016, Ministry of Tourism : expenditure to be met out of moneys granted and drawn from the consolidated fund, central government budget.', type: 'subtitle'
                                  }
                                ]
                              }
                            ])
      end
    end

    context 'with title with multiple parts (245 abfgknps)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [
              { 'a' => 'Main title :' },
              { 'b' => 'subtitle,' },
              { 'f' => 'inclusive dates,' },
              { 'g' => 'bulk dates,' },
              { 'k' => 'form,' },
              { 'n' => 'part name,' },
              { 'p' => 'part number,' },
              { 's' => 'version.' }
            ] } }
          ]
        }
      end

      it 'returns the title with structured value' do
        expect(build).to eq([
                              {
                                structuredValue: [
                                  { value: 'Main title', type: 'main title' },
                                  {
                                    value: 'subtitle, inclusive dates, bulk dates, form, part name, part number, version.', type: 'subtitle'
                                  }
                                ]
                              }
                            ])
      end
    end

    context 'with title with multiple scripts (245/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '245' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [
              { '6' => '880-01' },
              { 'a' => 'Publichnai͡a zhenshchina ili publichnai͡a lichnostʹ? :' },
              { 'b' => 'zhenskie obrazy v kino /' },
              { 'c' => 'S.A. Smagina.' }
            ] } },
            { '880' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [
              { '6' => '245-01' },
              { 'a' => 'Публичная женщина или публичная личность:' },
              { 'b' => 'женские образы в кино /' },
              { 'c' => 'С.А. Смагина.' }
            ] } }
          ]
        }
      end

      it 'returns the title with parallel values' do
        expect(build).to eq([
                              {
                                parallelValue: [
                                  {
                                    structuredValue: [
                                      { value: 'Publichnai͡a zhenshchina ili publichnai͡a lichnostʹ?',
                                        type: 'main title' },
                                      { value: 'zhenskie obrazy v kino', type: 'subtitle' }
                                    ]
                                  },
                                  {
                                    structuredValue: [
                                      { value: 'Публичная женщина или публичная личность', type: 'main title' },
                                      { value: 'женские образы в кино', type: 'subtitle' }
                                    ]
                                  }
                                ]
                              }
                            ])
      end
    end

    context 'with alternative title with display label (246)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '246' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [
              { 'i' => 'Title should read:' },
              { 'a' => 'Valses nobles et sentimentales :' },
              { 'b' => 'danses,' },
              { 'f' => '1905,' },
              { 'g' => 'manuscripts,' },
              { 'n' => 'op. 5,' },
              { 'p' => 'L\'oiseau.' }
            ] } }
          ]
        }
      end

      it 'returns the alternative title with display label' do
        expect(build).to eq([
                              {
                                value: 'Valses nobles et sentimentales : danses, 1905, manuscripts, op. 5, L\'oiseau.',
                                displayLabel: 'Title should read:',
                                type: 'alternative'
                              }
                            ])
      end
    end

    context 'with uniform title (240)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [
              { 'a' => 'Beowulf.' },
              { 'l' => 'English' }
            ] } }
          ]
        }
      end

      it 'returns the uniform title' do
        expect(build).to eq([
                              { value: 'Beowulf. English', type: 'uniform' }
                            ])
      end
    end

    context 'with uniform title with all subfields (240)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [
              { 'a' => 'Uniform title.' },
              { 'd' => 'Date of treaty,' },
              { 'f' => 'date of a work,' },
              { 'g' => 'misc info,' },
              { 'k' => 'form,' },
              { 'l' => 'language,' },
              { 'm' => 'medium of performance,' },
              { 'n' => 'part number,' },
              { 'o' => 'arranged music,' },
              { 'p' => 'part name,' },
              { 'r' => 'music key,' },
              { 's' => 'version.' }
            ] } }
          ]
        }
      end

      it 'returns the uniform title with all parts' do
        expect(build).to eq([
                              {
                                value: 'Uniform title. Date of treaty, date of a work, misc info, form, language, medium of performance, part number, arranged music, part name, music key, version.',
                                type: 'uniform'
                              }
                            ])
      end
    end

    context 'with uniform title (130)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '130' => { 'ind1' => '0', 'ind2' => ' ', 'subfields' => [
              { 'a' => 'Bible.' },
              { 'l' => 'Kituba (Congo (Democratic Republic)).' },
              { 'f' => '1990.' },
              { '0' => '(SIRSI)4061207' }
            ] } }
          ]
        }
      end

      it 'returns the uniform title' do
        expect(build).to eq([
                              { value: 'Bible. Kituba (Congo (Democratic Republic)). 1990.', type: 'uniform' }
                            ])
      end
    end

    context 'with uniform title with all subfields (130)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '130' => { 'ind1' => '0', 'ind2' => ' ', 'subfields' => [
              { 'a' => 'Uniform title.' },
              { 'd' => 'Date of treaty,' },
              { 'f' => 'date of a work,' },
              { 'g' => 'misc info,' },
              { 'k' => 'form,' },
              { 'l' => 'language,' },
              { 'm' => 'medium of performance,' },
              { 'n' => 'part number,' },
              { 'o' => 'arranged music,' },
              { 'p' => 'part name,' },
              { 'r' => 'music key,' },
              { 's' => 'version,' },
              { 't' => 'title.' }
            ] } }
          ]
        }
      end

      it 'returns the uniform title with all parts' do
        expect(build).to eq([
                              {
                                value: 'Uniform title. Date of treaty, date of a work, misc info, form, language, medium of performance, part number, arranged music, part name, music key, version, title.',
                                type: 'uniform'
                              }
                            ])
      end
    end

    context 'with alternative title (740)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '740' => { 'ind1' => '4', 'ind2' => ' ', 'subfields' => [
              { 'a' => 'The five red herrings.' },
              { 'p' => 'Prologue,' },
              { 'n' => 'chapter 1.' }
            ] } }
          ]
        }
      end

      it 'returns the alternative title' do
        expect(build).to eq([
                              { value: 'The five red herrings. Prologue, chapter 1.', type: 'alternative' }
                            ])
      end
    end

    context 'with alternative title with multiple scripts (246/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '246' => { 'ind1' => '3', 'ind2' => '0', 'subfields' => [
              { '6' => '880-01' },
              { 'a' => 'Nat͡sionalʹnye i mezhdunarodnye proekty razvitii͡a na evraziĭskom prostranstve i perspektivy ikh sopri͡azhenii͡a' }
            ] } },
            { '880' => { 'ind1' => '3', 'ind2' => '0', 'subfields' => [
              { '6' => '246-02' },
              { 'a' => 'Национальные и международные проекты развития на евразийском пространстве и перспективы их сопряжения' }
            ] } }
          ]
        }
      end

      it 'returns separate alternative titles' do
        expect(build).to eq([
                              {
                                value: 'Nat͡sionalʹnye i mezhdunarodnye proekty razvitii͡a na evraziĭskom prostranstve i perspektivy ikh sopri͡azhenii͡a', type: 'alternative'
                              },
                              {
                                value: 'Национальные и международные проекты развития на евразийском пространстве и перспективы их сопряжения', type: 'alternative'
                              }
                            ])
      end
    end
  end
end
