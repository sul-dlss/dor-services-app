# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS abstract <--> cocina mappings' do
  describe 'Single abstract' do
    xit 'updated spec not implemented' do
      let(:mods) do
        <<~XML
          <abstract>This is an abstract.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is an abstract.',
              type: 'abstract'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual abstract' do
    xit 'updated spec not implemented' do
      let(:mods) do
        <<~XML
          <abstract lang='eng' script='Latn' altRepGroup='1'>This is an abstract.</abstract>
          <abstract lang='rus' script='Cyrl' altRepGroup='1'>Это аннотация.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              type: 'abstract',
              parallelValue: [
                {
                  value: 'This is an abstract.',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  value: 'Это аннотация.',
                  valueLanguage: {
                    code: 'rus',
                    source: {
                      code: 'iso639-2b'
                    },
                    valueScript: {
                      code: 'Cyrl',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with type "summary"' do
    xit 'updated spec not implemented' do
      let(:mods) do
        <<~XML
          <abstract type="summary">This is a summary.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a summary.',
              type: 'summary'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with type "Summary"' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract type="Summary">This is a summary.</abstract>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract type="summary">This is a summary.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a summary.',
              type: 'summary'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with type "scope and content"' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract type="scope and content">This is a scope and content note.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a scope and content note.',
              type: 'scope and content'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with display label and type' do
    xit 'updated spec not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel='Synopsis'>This is a synopsis.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a synopsis.',
              type: 'abstract',
              displayLabel: 'Synopsis'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with displayLabel "Summary" and no type' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="Summary">Summary</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Summary',
              displayLabel: 'Summary'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with displayLabel "Subject" and no type' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="Subject">Subject</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Subject',
              displayLabel: 'Subject'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with displayLabel "Review" and no type' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="Review">Review</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Review',
              displayLabel: 'Review'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with displayLabel "Scope and content" and no type' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="Scope and content">Scope and content</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Scope and content',
              displayLabel: 'Scope and content'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with displayLabel "Abstract" and no type' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="Abstract">Abstract</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Abstract',
              displayLabel: 'Abstract'
            }
          ]
        }
      end
    end
  end

  describe 'Abstract with displayLabel "Content advice" and no type' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="Content advice">Content advice</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Content advice',
              displayLabel: 'Content advice'
            }
          ]
        }
      end
    end
  end

  describe 'Link to external value only' do
    xit 'updated spec not implemented' do
      let(:mods) do
        <<~XML
          <abstract xlink:href="http://hereistheabstract.com" />
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              valueAt: 'http://hereistheabstract.com',
              type: 'abstract'
            }
          ]
        }
      end
    end
  end
end
