# frozen_string_literal: true

# Based on https://github.com/amogil/rspec-deep-ignore-order-matcher/blob/master/lib/rspec_deep_ignore_order_matcher.rb
RSpec::Matchers.define :be_deep_equal do |expected|
  match { |actual| DeepEqual.match?(actual, expected) }

  # Added diffable because it is helpful for troubleshooting, even if it mistakenly adds spurious diffs.
  diffable

  failure_message do |actual|
    "expected that #{actual} would be deep equal with #{expected}. Differences in order shown in diff CAN BE IGNORED."
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not be deep equal with #{expected}. Differences in order shown in diff CAN BE IGNORED."
  end

  description do
    "be deep equal with #{expected}"
  end
end
