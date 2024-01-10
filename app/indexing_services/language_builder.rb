# frozen_string_literal: true

# Finds the language value to index from the cocina languages
class LanguageBuilder
  # @param [Array<Cocina::Models::Language>] languages
  # @return [String] the language value for Solr
  def self.build(languages)
    new(languages).build
  end

  def initialize(languages)
    @languages = languages
  end

  def build
    return unless languages

    languages.map do |lang|
      if iso_639?(lang)
        language_for_code(lang.code) || language_for_value(lang.value)
      elsif !lang.source
        lang.value
      end
    end.uniq.compact.presence
  end

  private

  attr_reader :languages

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def iso_639?(lang)
    lang.source&.code&.start_with?('iso639') ||
      lang.source&.uri&.start_with?(%r{https?://id.loc.gov/vocabulary/iso639}) ||
      lang.uri&.start_with?(%r{https?://id.loc.gov/vocabulary/iso639}) ||
      lang.source&.uri&.start_with?(%r{https?://iso639-3.sil.org/code/}) ||
      lang.uri&.start_with?(%r{https?://iso639-3.sil.org/code/})
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def language_for_code(code)
    # ISO_639 maps -1 and -2. LanguageList maps -3.
    ISO_639.find(code)&.english_name || LanguageList::LanguageInfo.find(code)&.name
  end

  # rubocop:disable Rails/DynamicFindBy
  def language_for_value(value)
    # ISO_639 maps -1 and -2. LanguageList maps -3.
    ISO_639.find_by_english_name(value)&.english_name || LanguageList::LanguageInfo.find(value)&.name
  end
  # rubocop:enable Rails/DynamicFindBy
end
