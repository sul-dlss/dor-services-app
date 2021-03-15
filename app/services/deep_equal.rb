# frozen_string_literal: true

# Deeply compares two objects, ignoring array order.
# Based on https://github.com/amogil/rspec-deep-ignore-order-matcher/blob/master/lib/rspec_deep_ignore_order_matcher.rb
class DeepEqual
  def self.match?(actual, expected)
    new(actual, expected).match?
  end

  def initialize(actual, expected)
    @actual = actual
    @expected = expected
  end

  def match?
    objects_match?(actual, expected)
  end

  private

  attr_reader :actual, :expected

  def objects_match?(actual_obj, expected_obj)
    return arrays_match?(actual_obj, expected_obj) if expected_obj.is_a?(Array) && actual_obj.is_a?(Array)
    return hashes_match?(actual_obj, expected_obj) if expected_obj.is_a?(Hash) && actual_obj.is_a?(Hash)

    expected_obj == actual_obj
  end

  def arrays_match?(actual_array, expected_array)
    exp = expected_array.clone
    actual_array.each do |a|
      index = exp.find_index { |e| objects_match? a, e }
      return false if index.nil?

      exp.delete_at(index)
    end
    exp.empty?
  end

  def hashes_match?(actual_hash, expected_hash)
    return false unless actual_hash.keys.sort == expected_hash.keys.sort

    actual_hash.each { |key, value| return false unless objects_match? value, expected_hash[key] }
    true
  end
end
