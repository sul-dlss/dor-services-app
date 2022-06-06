# frozen_string_literal: true

# Custom date validation.
# Note that this is currently used for reports.
# Once remediation of dates is complete, it will be moved to cocina models for validation.
class DateTimeValidator
  YEAR = '(\d{4})'

  MONTH = '(0[1-9]|1[012])'

  DAY = '(0[1-9]|[12]\d|3[01])'

  HOUR = '([01]\d|2[0123])'

  MINUTE = '([0-5]\d)'

  SECOND = '([0-5]\d)'

  SECOND_FRACTION = '(\d+)'

  TIME_ZONE = "(\\+#{HOUR}:#{MINUTE})?"

  COMMON_FORMATS = [
    Regexp.new("^#{YEAR}$"),
    Regexp.new("^#{YEAR}-#{MONTH}$"),
    Regexp.new("^#{YEAR}-#{MONTH}-#{DAY}$"),
    Regexp.new("^#{YEAR}-#{MONTH}-#{DAY}T#{HOUR}:#{MINUTE}#{TIME_ZONE}$"),
    Regexp.new("^#{YEAR}-#{MONTH}-#{DAY}T#{HOUR}:#{MINUTE}:#{SECOND}#{TIME_ZONE}$"),
    Regexp.new("^#{YEAR}-#{MONTH}-#{DAY}T#{HOUR}:#{MINUTE}:#{SECOND}\.#{SECOND_FRACTION}#{TIME_ZONE}$")
  ].freeze

  ISO8601_FORMATS = COMMON_FORMATS + [
    Regexp.new("^#{YEAR}#{MONTH}--$"),
    Regexp.new("^#{YEAR}#{MONTH}#{DAY}$"),
    Regexp.new("^#{YEAR}#{MONTH}#{DAY}T#{HOUR}#{MINUTE}$"),
    Regexp.new("^#{YEAR}#{MONTH}#{DAY}T#{HOUR}#{MINUTE}#{SECOND}$"),
    Regexp.new("^#{YEAR}#{MONTH}#{DAY}#{HOUR}#{MINUTE}$"),
    Regexp.new("^#{YEAR}#{MONTH}#{DAY}#{HOUR}#{MINUTE}#{SECOND}$")
  ]

  W3CDTF_FORMATS = COMMON_FORMATS

  EDTF_FORMATS = COMMON_FORMATS + [
    Regexp.new("^-#{YEAR}$")
  ]

  def self.iso8601?(date_str)
    new.iso8601?(date_str)
  end

  def self.w3cdtf?(date_str)
    new.w3cdtf?(date_str)
  end

  def self.edtf?(date_str)
    new.edtf?(date_str)
  end

  def iso8601?(date_str)
    valid?(date_str, ISO8601_FORMATS)
  end

  def w3cdtf?(date_str)
    valid?(date_str, W3CDTF_FORMATS)
  end

  def edtf?(date_str)
    valid?(date_str, EDTF_FORMATS)
  end

  private

  def valid?(date_str, formats)
    formats.any? do |format|
      format.match?(date_str)
    end
  end
end
