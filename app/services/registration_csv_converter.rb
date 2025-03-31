# frozen_string_literal: true

# Convert CSV to JSON for registration
class RegistrationCsvConverter
  include Dry::Monads[:result]

  CONTENT_TYPES = [Cocina::Models::ObjectType.book,
                   Cocina::Models::ObjectType.document,
                   Cocina::Models::ObjectType.file,
                   Cocina::Models::ObjectType.geo,
                   Cocina::Models::ObjectType.image,
                   Cocina::Models::ObjectType.map,
                   Cocina::Models::ObjectType.media,
                   Cocina::Models::ObjectType.three_dimensional,
                   Cocina::Models::ObjectType.webarchive_binary,
                   Cocina::Models::ObjectType.webarchive_seed].freeze

  # @param [String] csv_string CSV string
  # @return [Array<Result>] a list of registration requests suitable for passing off to dor-services-client
  def self.convert(csv_string:)
    new(csv_string:).convert
  end

  attr_reader :csv_string

  # @param [String] csv_string CSV string
  def initialize(csv_string:)
    @csv_string = csv_string
  end

  # @return [Result] an array of dry-monad results
  # Columns:
  #   0: druid (required)
  #   1: administrative_policy_object (required)
  #   2: collection (optional)
  #   3: initial_workflow (required)
  #   4: content_type (required)
  #   5: source_id (required)
  #   6: catkey or folio_id (optional)
  #   7: barcode (optional)
  #   8: label (required unless a catkey or folio_id have been entered)
  #   9: rights_view (required)
  #  10: rights_download (required)
  #  11: rights_location (required if "view" or "download" uses "location-based")
  #  12: rights_controlledDigitalLending (optional: "true" is valid only when "view" is "stanford" and "download"
  #   is "none")
  #  13: project_name (optional)
  #  14: tags (optional, may repeat)

  def convert
    CSV.parse(csv_string, headers: true).map { |row| { druid: row['druid'], cocina_request_object: convert_row(row) } }
  end

  def convert_row(row)
    model = Cocina::Models::RequestDRO.new(model_params(row))
    Success(model:,
            workflow: row.fetch('initial_workflow'),
            tags: tags(row))
  rescue Cocina::Models::ValidationError => e
    Failure(e)
  end

  def model_params(row)
    model_params = {
      type: dro_type(row.fetch('content_type')),
      version: 1,
      label: row['label'],
      administrative: {
        hasAdminPolicy: row.fetch('administrative_policy_object')
      },
      identification: {
        sourceId: row.fetch('source_id'),
        barcode: row['barcode']
      }.compact
    }

    model_params[:structural] = structural(row)
    model_params[:access] = access(row)
    project_name = row['project_name']
    model_params[:administrative][:partOfProject] = project_name if project_name.present?
    model_params
  end

  def tags(row)
    [].tap do |tags|
      tag_count = row.headers.count('tags')
      tag_count.times { |n| tags << row.field('tags', n + row.index('tags')) }
    end.compact
  end

  def dro_type(content_type) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
    # for CSV registration, we already have the URI
    return content_type if CONTENT_TYPES.include?(content_type)

    case content_type.downcase
    when 'image'
      Cocina::Models::ObjectType.image
    when '3d'
      Cocina::Models::ObjectType.three_dimensional
    when 'map'
      Cocina::Models::ObjectType.map
    when 'media'
      Cocina::Models::ObjectType.media
    when 'document'
      Cocina::Models::ObjectType.document
    when /^manuscript/
      Cocina::Models::ObjectType.manuscript
    when 'book', 'book (ltr)', 'book (rtl)'
      Cocina::Models::ObjectType.book
    when 'geo'
      Cocina::Models::ObjectType.geo
    when 'webarchive-seed'
      Cocina::Models::ObjectType.webarchive_seed
    when 'webarchive-binary'
      Cocina::Models::ObjectType.webarchive_binary
    else
      Cocina::Models::ObjectType.object
    end
  end

  def structural(row)
    {}.tap do |structural|
      collection = row['collection']
      structural[:isMemberOf] = [collection] if collection
      reading_order = row['reading_order']
      structural[:hasMemberOrders] = [{ viewingDirection: reading_order }] if reading_order.present?
    end
  end

  def access(row) # rubocop:disable Metrics/AbcSize
    {}.tap do |access|
      access[:view] = row['rights_view']
      access[:download] = row['rights_download'] || ('none' if %w[citation-only dark].include? access[:view])
      access[:location] = row.fetch('rights_location') if [access[:view], access[:download]].include?('location-based')
      cdl = row['rights_controlledDigitalLending']
      access[:controlledDigitalLending] = ActiveModel::Type::Boolean.new.cast(cdl) if cdl.present?
    end.compact
  end
end
