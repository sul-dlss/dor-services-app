# frozen_string_literal: true

# Model for a semantic version tag.
# From https://github.com/sul-dlss/dor-services/blob/main/lib/dor/datastreams/version_metadata_ds.rb
class VersionTag
  include Comparable

  attr_reader :major, :minor, :admin

  def <=>(other)
    diff = @major <=> other.major
    return diff if diff != 0

    diff = @minor <=> other.minor
    return diff if diff != 0

    @admin <=> other.admin
  end

  # @param [String] raw_tag the value of the tag attribute from a Version node
  def self.parse(raw_tag)
    return nil unless raw_tag =~ /(\d+)\.(\d+)\.(\d+)/

    VersionTag.new Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
  end

  def initialize(maj, min, adm)
    @major = maj.to_i
    @minor = min.to_i
    @admin = adm.to_i
  end

  # @param [Symbol] sig which part of the version tag to increment
  #  :major, :minor, :admin
  def increment(sig)
    case sig
    when :major
      @major += 1
      @minor = 0
      @admin = 0
    when :minor
      @minor += 1
      @admin = 0
    when :admin
      @admin += 1
    end
    self
  end

  def to_s
    "#{@major}.#{@minor}.#{admin}"
  end
end
