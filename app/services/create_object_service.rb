# frozen_string_literal: true

# This handles all of the business logic around registering an object.
# This includes:
#   Minting a druid identifier
#   Importing metadata from ILS (Folio) if there is a catalogRecordId
#   Adding project tags to the project tag store
#   Adding a default description if none is provided
#   Importing access from the admin_policy if none is provided
#   Minting a doi if requested
class CreateObjectService
  # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy] cocina_object # rubocop:disable Layout/LineLength
  # @param [boolean] assign_doi
  # @param [string] who the sunetid of the user performing the update
  # @param [#call] id_minter assigns identifiers. You can provide your own minter if you want to use a specific druid
  # for an item.
  # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] # rubocop:disable Layout/LineLength
  # @raise [Catalog::MarcService::MarcServiceError::CatalogRecordNotFoundError] if catalog identifer not found when
  # refreshing descMetadata
  # @raise [Catalog::MarcService::MarcServiceError::CatalogResponseError] if other error occurred refreshing
  # descMetadata from catalog source
  # @raise [Cocina::ValidationError] raised when validation of the Cocina object fails.
  def self.create(cocina_request_object, assign_doi: false, who: nil, id_minter: -> { SuriService.mint_id })
    new(id_minter:).create(cocina_request_object, assign_doi:, who:)
  end

  def initialize(id_minter: -> { SuriService.mint_id })
    @id_minter = id_minter
  end

  # @raise Catalog::MarcService::MarcServiceError
  # @raise [Cocina::ValidationError] if externalIdentifier or sourceId not unique
  def create(cocina_request_object, assign_doi: false, who: nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    ensure_ur_admin_policy_exists(cocina_request_object)
    Cocina::ObjectValidator.validate(cocina_request_object)
    updated_cocina_request_object = merge_access_for(cocina_request_object)
    druid = id_minter.call
    updated_cocina_request_object = sync_from_catalog(updated_cocina_request_object, druid)
    updated_cocina_request_object = add_description(updated_cocina_request_object)
    cocina_object = cocina_from_request(updated_cocina_request_object, druid, assign_doi)
    cocina_object = assign_doi(cocina_object) if assign_doi
    cocina_object_with_metadata = RepositoryObject.create_from(cocina_object:).to_cocina_with_metadata

    add_project_tag(druid, cocina_request_object)

    EventFactory.create(druid:, event_type: 'registration', data: { who:, request: cocina_object.to_h })

    # Broadcast this to a topic
    Notifications::ObjectCreated.publish(model: cocina_object_with_metadata)
    Indexer.reindex(cocina_object: cocina_object_with_metadata)
    cocina_object_with_metadata
  rescue ActiveRecord::RecordNotUnique => e
    message = if e.message.include?('index_repository_objects_on_source_id')
                source_id = cocina_object.identification.sourceId
                druid = CocinaObjectStore.find_by_source_id(source_id).externalIdentifier # rubocop:disable Rails/DynamicFindBy
                "An object (#{druid}) with the source ID '#{source_id}' has already been registered."
              else
                'ExternalIdentifier or sourceId is not unique.'
              end
    raise Cocina::ValidationError.new(message, status: :conflict)
  end

  private

  attr_reader :id_minter

  # If an object references the Ur-AdminPolicy, it has to exist first.
  # This is particularly important in testing, where the repository may be empty.
  def ensure_ur_admin_policy_exists(cocina_object)
    unless Settings.enabled_features.create_ur_admin_policy &&
           cocina_object.administrative.hasAdminPolicy == Settings.ur_admin_policy.druid
      return
    end

    CocinaObjectStore.exists?(Settings.ur_admin_policy.druid,
                              type: CocinaObjectStore::ADMIN_POLICY) || UrAdminPolicyFactory.create
  end

  # Merge the rights, use statement, license and copyright statement from the
  # admin policy to the provided DRO or collection.
  # @return[Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy]
  def merge_access_for(cocina_object)
    return cocina_object if cocina_object.admin_policy?

    apo_object = CocinaObjectStore.find(cocina_object.administrative.hasAdminPolicy)
    cocina_object.new(access: AccessMergeService.merge(cocina_object, apo_object))
  end

  # Sync from ILS (Folio) if a catalog record identifier is present
  # @raise Catalog::MarcService::MarcServiceError
  def sync_from_catalog(cocina_request_object, druid)
    return cocina_request_object if cocina_request_object.admin_policy?

    result = RefreshDescriptionFromCatalog.run(cocina_object: cocina_request_object, druid:)
    return cocina_request_object if result.failure?

    description_props = result.value!.description_props
    # Remove PURL since this is still a request
    description_props.delete(:purl)
    label = ModsUtils.label(result.value!.mods_ng_xml)
    cocina_request_object.new(label:, description: description_props)
  end

  def add_description(cocina_request_object)
    return cocina_request_object if cocina_request_object.description.present?

    cocina_request_object.new(description: { title: [{ value: cocina_request_object.label }] })
  end

  def assign_doi(cocina_object)
    return cocina_object unless cocina_object.dro?

    identification = cocina_object.identification || Cocina::Models::Identification.new
    cocina_object.new(identification: identification.new(doi: Doi.for(druid: cocina_object.externalIdentifier)))
  end

  # Converts from Cocina::Models::RequestDRO|RequestCollection|RequestAdminPolicy to Cocina::Models::DRO|Collection||AdminPolicy # rubocop:disable Layout/LineLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def cocina_from_request(cocina_request_object, druid, assign_doi) # rubocop:disable Metrics/MethodLength
    props = cocina_request_object.to_h.with_indifferent_access
    props[:externalIdentifier] = druid

    # Add purl and DOI to description and citation
    if props[:description].present?
      purl = Purl.for(druid:)
      props[:description][:purl] = purl

      # This replaces the :link: and :doi: placeholders in the citation.
      # This is specifically for H2, but could be utilized by any client that provides preferred citation.
      doi = assign_doi ? "https://doi.org/#{Doi.for(druid:)}." : ''
      Array(props[:description][:note]).each do |note|
        note[:value] = note[:value].gsub(':link:', purl) if note[:type] == 'preferred citation' && note[:value]
        note[:value] = note[:value].gsub(':doi:', doi) if note[:type] == 'preferred citation' && note[:value]
      end
    end

    # Add externalIdentifiers to structural
    Array(props.dig(:structural, :contains)).each do |fileset_props|
      fileset_id = fileset_props[:externalIdentifier] || Cocina::IdGenerator.generate_or_existing_fileset_id(druid:)
      fileset_props[:externalIdentifier] = fileset_id
      Array(fileset_props.dig(:structural, :contains)).each do |file_props|
        # NOTE: externalIdentifier is an optional property on a RequestFile
        file_id = file_props[:externalIdentifier] ||
                  Cocina::IdGenerator.generate_or_existing_file_id(druid:,
                                                                   resource_id: fileset_id,
                                                                   file_id: file_props[:filename])
        unless Cocina::IdGenerator.valid_file_id?(file_id)
          Honeybadger.notify("File ID is not in the expected format. It should begin with #{Cocina::IdGenerator::ID_NAMESPACE}",
                             context: { file_id:, external_identifier: druid })
        end
        file_props[:externalIdentifier] = file_id
      end
    end

    # Remove partOfProject
    props[:administrative].delete(:partOfProject) if props[:administrative].present?

    # These are not required in requests
    props[:structural] = {} if cocina_request_object.dro? && props[:structural].nil?
    props[:identification] = {} if cocina_request_object.collection? && props[:identification].nil?

    Cocina::Models.build(props)
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def add_project_tag(druid, cocina_request_object)
    return if cocina_request_object.admin_policy? || !cocina_request_object.administrative.partOfProject

    tags = ["Project : #{cocina_request_object.administrative.partOfProject}"]
    AdministrativeTags.create(identifier: druid, tags:)
  end
end
