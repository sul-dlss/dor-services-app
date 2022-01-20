# typed: true
# frozen_string_literal: true

# Provides RSpec matchers for Cocina models
module CocinaMatchers
  extend RSpec::Matchers::DSL

  # The `equal_cocina_model` matcher compares a JSON string as actual value
  # against a Cocina model coerced to JSON as expected value. We want to compare
  # these as JSON rather than as hashes, else we'll have to start
  # deep-converting some values within the hashes, thinking of date/time values
  # in particular. This matching behavior continues what dor-services-app was
  # already doing before this custom matcher was written.
  #
  # Note, though, that when actual and expected values do *not* match, we coerce
  # both values to hashes to allow the `super_diff` gem to highlight the areas
  # that differ. This is easier to scan than two giant JSON strings.
  matcher :equal_cocina_model do |expected|
    match do |actual|
      Cocina::Models.build(JSON.parse(actual)).to_json == expected.to_json
    rescue NoMethodError
      warn "Could not match cocina models because expected is not a valid JSON string: #{expected}"
      false
    end

    failure_message do |actual|
      SuperDiff::EqualityMatchers::Hash.new(
        expected: expected.to_h.deep_symbolize_keys,
        actual: JSON.parse(actual, symbolize_names: true)
      ).fail
    rescue StandardError => e
      "ERROR in CocinaMatchers: #{e}"
    end
  end
end

RSpec.configure do |config|
  config.include CocinaMatchers, type: :request
end
