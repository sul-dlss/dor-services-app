# frozen_string_literal: true

FactoryBot.define do
  sequence :unique_druid do |n|
    letters = 'bcdfghjkmnpqrstvwxyz'.chars.freeze

    # this should give us 10000000 (1000 * 10000) unique druids:
    # * start the counter from 0.
    # * div the counter so that the 3 digit cluster increments every time the 4 digit cluster rolls over.
    # The letters are just chosen at random.
    idx = n - 1
    format_str = 'druid:%s%s%03d%s%s%04d'
    format(format_str, letters.sample, letters.sample,
           idx / 10_000, letters.sample, letters.sample, idx)
  end
end
