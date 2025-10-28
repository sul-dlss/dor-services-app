# frozen_string_literal: true

# Migrate ticket tags to the Ticket : tag format
class TicketTagMigrator
  TICKET_PREFIXES = %w[
    BBOOKS-
    CONSERVREQ-
    DIGREQ-
    FORENSICSLAB-
    LEGACY-
    MAPS-
    PROJQUEUE-
    REQDIGCOPY-
    SDRGET-
    SDRO-
    SDROTL-
    SMPLSMALL-
    SPECPAT-
    SPECTPAT-
  ].freeze

  TICKET_NORMALIZATION = {
    'Legacy-' => 'LEGACY-',
    'legacy-' => 'LEGACY-',
    'Projqueue-' => 'PROJQUEUE-',
    'Projqeue-' => 'PROJQUEUE-',
    'DIGERQ-' => 'DIGREQ-',
    'DIGIREQ-' => 'DIGREQ-',
    'DIGREG-' => 'DIGREQ-',
    'DIGRQ-' => 'DIGREQ-',
    'SPECTPAT-' => 'SPECPAT-'
  }.freeze

  SKIPPED_FIRST_PARTS = %w[
    JIRA
    Decommissioned
    DPG
    Decommissoned
    Recommission
    Decommission
    Review
    Tombstone
    remediation
  ].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(tag:)
    @tag = tag
  end

  # @return [Array<String>] changed tags if any. Note this is an array since a tag may be split.
  def call
    return [] unless matches_ticket_prefix? || matches_normalization_prefix?
    return [] if project_tag? || already_ticket_tag?

    TICKET_NORMALIZATION.each do |wrong_prefix, right_prefix|
      @tag = tag.gsub(wrong_prefix, right_prefix)
    end

    [(['Ticket'] + ticket_parts).join(' : ')].tap do |changed_tags|
      changed_tags.prepend(first_part.join(' : ')) if add_first_part?
    end
  end

  private

  attr_reader :tag

  def matches_ticket_prefix?
    TICKET_PREFIXES.any? { |prefix| tag.include?(prefix) }
  end

  def matches_normalization_prefix?
    TICKET_NORMALIZATION.keys.any? { |wrong_prefix| tag.include?(wrong_prefix) }
  end

  def parts
    tag.split(/\s+:\s+/)
  end

  def ticket_parts_index
    @ticket_parts_index ||= parts.find_index { |part| TICKET_PREFIXES.any? { |prefix| part.include?(prefix) } }
  end

  def first_part
    @first_part ||= ticket_parts_index.positive? ? parts[0..(ticket_parts_index - 1)] : nil
  end

  def ticket_parts
    @ticket_parts ||= parts[ticket_parts_index..]
  end

  def project_tag?
    parts.first == 'Project'
  end

  def already_ticket_tag?
    parts.first == 'Ticket'
  end

  def add_first_part?
    first_part.present? && SKIPPED_FIRST_PARTS.exclude?(first_part.first)
  end
end
