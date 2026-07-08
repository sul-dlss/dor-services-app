# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Builders::FormatBuilder do
  describe '.build' do
    subject(:build) { described_class.build(forms) }

    describe 'Archived website' do
      context 'with a genre of Archived website' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Archived website', type: 'genre')
          ]
        end

        it 'includes Archived website' do
          expect(build).to eq(['Archived website'])
        end
      end

      context 'with a genre of archived website in a different case' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'archived website', type: 'genre')
          ]
        end

        it 'includes Archived website' do
          expect(build).to eq(['Archived website'])
        end
      end
    end

    describe 'No format specified' do
      context 'with an unrelated genre' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'photographs', type: 'genre')
          ]
        end

        it 'returns No format specified' do
          expect(build).to eq(['No format specified'])
        end
      end

      context 'with a non-genre form of the same value' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Archived website', type: 'resource type')
          ]
        end

        it 'returns No format specified' do
          expect(build).to eq(['No format specified'])
        end
      end

      context 'with no forms' do
        let(:forms) { [] }

        it 'returns No format specified' do
          expect(build).to eq(['No format specified'])
        end
      end

      context 'with nil forms' do
        let(:forms) { nil }

        it 'returns No format specified' do
          expect(build).to eq(['No format specified'])
        end
      end
    end

    describe 'Archive/Manuscript' do
      context 'with a resource type of Collection sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Collection', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Archive/Manuscript' do
          expect(build).to eq(['Archive/Manuscript'])
        end
      end

      context 'with a resource type of collection sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'collection', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Archive/Manuscript' do
          expect(build).to eq(['Archive/Manuscript'])
        end
      end

      context 'with a resource type of Manuscript sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Manuscript', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Archive/Manuscript' do
          expect(build).to eq(['Archive/Manuscript'])
        end
      end

      context 'with a resource type of manuscript sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'manuscript', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Archive/Manuscript' do
          expect(build).to eq(['Archive/Manuscript'])
        end
      end

      context 'with a resource type of Mixed material sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Mixed material', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Archive/Manuscript' do
          expect(build).to eq(['Archive/Manuscript'])
        end
      end

      context 'with a resource type of mixed material sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'mixed material', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Archive/Manuscript' do
          expect(build).to eq(['Archive/Manuscript'])
        end
      end
    end

    describe 'Dataset' do
      context 'with a resource type of Dataset sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Dataset', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Dataset' do
          expect(build).to eq(['Dataset'])
        end
      end

      context 'with a genre of dataset' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'dataset', type: 'genre')
          ]
        end

        it 'includes Dataset' do
          expect(build).to eq(['Dataset'])
        end
      end

      context 'with a genre of Data set' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Data set', type: 'genre')
          ]
        end

        it 'includes Dataset' do
          expect(build).to eq(['Dataset'])
        end
      end
    end

    describe 'Image' do
      context 'with a resource type of Still image sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Still image', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Image' do
          expect(build).to eq(['Image'])
        end
      end

      context 'with a resource type of still image sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'still image', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Image' do
          expect(build).to eq(['Image'])
        end
      end
    end

    describe 'Journal/Periodical' do
      context 'with a genre of Periodicals' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Periodicals', type: 'genre')
          ]
        end

        it 'includes Journal/Periodical' do
          expect(build).to eq(['Journal/Periodical'])
        end
      end
    end

    describe 'Map' do
      context 'with a resource type of Cartographic sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Cartographic', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Map' do
          expect(build).to eq(['Map'])
        end
      end

      context 'with a resource type of cartographic sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'cartographic', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Map' do
          expect(build).to eq(['Map'])
        end
      end
    end

    describe 'Music score' do
      context 'with a resource type of Notated music sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Notated music', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Music score' do
          expect(build).to eq(['Music score'])
        end
      end

      context 'with a resource type of Notated music sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Notated music', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Music score' do
          expect(build).to eq(['Music score'])
        end
      end
    end

    describe 'Newspaper' do
      context 'with a genre of Newspapers' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Newspapers', type: 'genre')
          ]
        end

        it 'includes Newspaper' do
          expect(build).to eq(['Newspaper'])
        end
      end
    end

    describe 'Object' do
      context 'with a resource type of Artifact sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Artifact', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Object' do
          expect(build).to eq(['Object'])
        end
      end

      context 'with a resource type of three dimensional object sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'three dimensional object', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Object' do
          expect(build).to eq(['Object'])
        end
      end
    end

    describe 'Software/Multimedia' do
      context 'with a resource type of Digital sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Digital', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Software/Multimedia' do
          expect(build).to eq(['Software/Multimedia'])
        end
      end

      context 'with a resource type of Multimedia sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Multimedia', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Software/Multimedia' do
          expect(build).to eq(['Software/Multimedia'])
        end
      end

      context 'with a resource type of software, multimedia sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'software, multimedia', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Software/Multimedia' do
          expect(build).to eq(['Software/Multimedia'])
        end
      end
    end

    describe 'Sound recording' do
      context 'with a resource type of Audio sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Audio', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Sound recording' do
          expect(build).to eq(['Sound recording'])
        end
      end

      context 'with a resource type of sound recording sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'sound recording', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Sound recording' do
          expect(build).to eq(['Sound recording'])
        end
      end

      context 'with a resource type of sound recording-musical sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'sound recording-musical', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Sound recording' do
          expect(build).to eq(['Sound recording'])
        end
      end

      context 'with a resource type of sound recording-nonmusical sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'sound recording-nonmusical', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Sound recording' do
          expect(build).to eq(['Sound recording'])
        end
      end
    end

    describe 'Video/Film' do
      context 'with a resource type of Moving image sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Moving image', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Video/Film' do
          expect(build).to eq(['Video/Film'])
        end
      end

      context 'with a resource type of moving image sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'moving image', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Video/Film' do
          expect(build).to eq(['Video/Film'])
        end
      end
    end

    describe 'Book' do
      context 'with a resource type of Text sourced from LC Resource Types Scheme' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Text', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' })
          ]
        end

        it 'includes Book' do
          expect(build).to eq(['Book'])
        end
      end

      context 'with a resource type of text sourced from MODS resource types' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'text', type: 'resource type',
                                                 source: { value: 'MODS resource types' })
          ]
        end

        it 'includes Book' do
          expect(build).to eq(['Book'])
        end
      end

      context 'with a resource type of Text and a genre of Archived website' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Text', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' }),
            Cocina::Models::DescriptiveValue.new(value: 'Archived website', type: 'genre')
          ]
        end

        it 'does not include Book' do
          expect(build).to eq(['Archived website'])
        end
      end

      context 'with a resource type of Text and a genre of dataset' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Text', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' }),
            Cocina::Models::DescriptiveValue.new(value: 'dataset', type: 'genre')
          ]
        end

        it 'does not include Book' do
          expect(build).to eq(['Dataset'])
        end
      end

      context 'with a resource type of Text and a genre of Data set' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Text', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' }),
            Cocina::Models::DescriptiveValue.new(value: 'Data set', type: 'genre')
          ]
        end

        it 'does not include Book' do
          expect(build).to eq(['Dataset'])
        end
      end

      context 'with a resource type of Text and a genre of Periodicals' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Text', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' }),
            Cocina::Models::DescriptiveValue.new(value: 'Periodicals', type: 'genre')
          ]
        end

        it 'does not include Book' do
          expect(build).to eq(['Journal/Periodical'])
        end
      end

      context 'with a resource type of Text and a genre of Newspaper' do
        let(:forms) do
          [
            Cocina::Models::DescriptiveValue.new(value: 'Text', type: 'resource type',
                                                 source: { value: 'LC Resource Types Scheme' }),
            Cocina::Models::DescriptiveValue.new(value: 'Newspaper', type: 'genre')
          ]
        end

        it 'does not include Book' do
          expect(build).to eq(['No format specified'])
        end
      end
    end
  end
end
