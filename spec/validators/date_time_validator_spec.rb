# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DateTimeValidator do
  let(:common_dates) do
    [
      '1997',
      '1997-07',
      '1997-12',
      '1997-07-16',
      '1997-07-16T19:20',
      '1997-07-16T00:00',
      '1997-07-16T23:59',
      '1997-07-16T19:20:30',
      '1997-07-16T19:20:00',
      '1997-07-16T19:20:59',
      '1997-07-16T19:20:30.4',
      '1997-07-16T19:20:30.45',
      '1997-07-16T19:20+01:00',
      '1997-07-16T19:20:30+01:00',
      '1997-07-16T19:20:30.45+01:00'
    ]
  end

  let(:common_invalid_dates) do
    [
      'foo',
      '199?',
      ' 1997',
      '1997 ',
      '1997-00',
      '1997-13',
      '1997-07-00',
      '1997-07-33',
      '1997-07-16T24:20',
      '1997-07-16T19:60',
      '1997-07-16T19:20:60',
      '1997-07-16T19:20:30.45+24:00',
      '1997-07-16T19:20:30.45+01:60'
    ]
  end

  let(:iso8601_dates) do
    [
      '19970716',
      '199707--',
      '19970716T1920',
      '19970716T192030',
      '199707161920',
      '19970716192030'
    ]
  end

  let(:edtf_dates) do
    [
      '-3999'
    ]
  end

  it 'is valid ISO8601' do
    common_dates.each do |date_str|
      expect(described_class.iso8601?(date_str)).to be true
    end
    iso8601_dates.each do |date_str|
      expect(described_class.iso8601?(date_str)).to be true
    end
  end

  it 'is invalid ISO8601' do
    common_invalid_dates.each do |date_str|
      expect(described_class.iso8601?(date_str)).to be false
    end
    edtf_dates.each do |date_str|
      expect(described_class.iso8601?(date_str)).to be false
    end
  end

  it 'is valid W3CDTF' do
    common_dates.each do |date_str|
      expect(described_class.w3cdtf?(date_str)).to be true
    end
  end

  it 'is invalid W3CDTF' do
    common_invalid_dates.each do |date_str|
      expect(described_class.w3cdtf?(date_str)).to be false
    end

    iso8601_dates.each do |date_str|
      expect(described_class.w3cdtf?(date_str)).to be false
    end

    edtf_dates.each do |date_str|
      expect(described_class.w3cdtf?(date_str)).to be false
    end
  end

  it 'is valid EDTF' do
    common_dates.each do |date_str|
      expect(described_class.edtf?(date_str)).to be true
    end

    edtf_dates.each do |date_str|
      expect(described_class.edtf?(date_str)).to be true
    end
  end

  it 'is invalid EDTF' do
    common_invalid_dates.each do |date_str|
      expect(described_class.edtf?(date_str)).to be false
    end

    iso8601_dates.each do |date_str|
      expect(described_class.edtf?(date_str)).to be false
    end
  end
end
