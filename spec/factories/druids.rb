# frozen_string_literal: true

FactoryBot.define do
  sequence :unique_druid do |n|
    # this should give us 10000000 (1000 * 10000) unique druids:
    # * start the counter from 0.
    # * div the counter so that the 3 digit cluster increments every time the 4 digit cluster rolls over.
    idx = n - 1
    format('druid:zx%03dwv%04d', idx / 10000, idx) # rubocop:disable Style/FormatStringToken annotations make this string less readable
  end
end
