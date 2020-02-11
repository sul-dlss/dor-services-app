# frozen_string_literal: true

# Registers an object. Creates a skeleton object in Fedora with a Druid.
# rubocop:disable Metrics/ClassLength
class RegistrationService
  class << self
    # @param [Hash] params
    # @param [EventFactory] event_factory
    # @see register_object similar but different
    # @return [Dor::RegistrationResponse]
    def create_from_request(params, event_factory: EventFactory)
      dor_params = registration_request_params(params)

      request = RegistrationRequest.new(dor_params)
      dor_obj = register_object(request)
      pid = dor_obj.pid
      event_factory.create(druid: pid, event_type: 'registration', data: params)
      location = URI.parse(Dor::Config.fedora.safeurl.sub(%r{/*$}, '/')).merge("objects/#{pid}").to_s

      Dor::RegistrationResponse.new(dor_params.merge(location: location, pid: pid))
    end

    private

    # Transform the user provided parameters into something suitable to pass to RegistrationRequest
    def registration_request_params(params)
      other_ids = namespace_identifiers(Array(params[:other_id]))
      handle_auto_label(params, other_ids)
      params.slice(:pid, :admin_policy, :label, :object_type, :parent, :seed_datastream, :rights, :metadata_source, :collection, :abstract)
            .merge(
              content_model: params[:model],
              other_ids: ids_to_hash(other_ids),
              source_id: ids_to_hash(params[:source_id]),
              tags: params[:tag] || []
            )
            .reject { |_k, v| v.nil? }
    end

    # This mutates the value of params[:label] if the value is currently ':auto'
    def handle_auto_label(params, other_ids)
      return unless params[:label] == ':auto'

      metadata_id = MetadataService.resolvable(other_ids).first
      params[:label] = MetadataService.label_for(metadata_id)
    end

    def namespace_identifiers(other_ids)
      other_ids.map do |id|
        if id =~ /^symphony:(.+)$/
          "#{$1.length < 14 ? 'catkey' : 'barcode'}:#{$1}"
        else
          id
        end
      end
    end

    # @TODO: these duplicate checks could be combined into 1 query

    # @param [String] pid an ID to check, if desired.  If not passed (or nil), a new ID is minted
    # @return [String] a pid you can use immidately, either freshly minted or your checked value
    # @raise [Dor::DuplicateIdError]
    def unduplicated_pid(pid = nil)
      return Dor::SuriService.mint_id unless pid

      existing_pid = Dor::SearchService.query_by_id(pid).first
      raise Dor::DuplicateIdError.new(existing_pid), "An object with the PID #{pid} has already been registered." unless existing_pid.nil?

      pid
    end

    # @param [String] source_id_string a fully qualified source:val or empty string
    # @return [String] the same qualified source:id for immediate use
    # @raise [Dor::DuplicateIdError]
    def check_source_id(source_id_string)
      return '' if source_id_string == ''
      unless Dor::SearchService.query_by_id(source_id_string.to_s).first.nil?
        raise Dor::DuplicateIdError.new(source_id_string), "An object with the source ID '#{source_id_string}' has already been registered."
      end

      source_id_string
    end

    # @param [RegistrationRequest] RegistrationRequest
    def register_object(request)
      request.validate!

      # Check for sourceId conflict *before* potentially minting PID
      source_id_string = check_source_id [request.source_id.keys.first, request.source_id[request.source_id.keys.first]].compact.join(':')
      pid = unduplicated_pid(request.pid)
      apo_object = Dor.find(request.admin_policy)
      new_item = request.item_class.new(pid: pid,
                                        admin_policy_object_id: apo_object.id,
                                        source_id: source_id_string,
                                        label: request.label)
      idmd = new_item.identityMetadata
      idmd.objectId = pid
      idmd.objectCreator = 'DOR'
      idmd.objectLabel = request.label
      idmd.objectType = request.object_type
      idmd.tag = request.tags
      request.other_ids.each_pair { |name, value| idmd.add_otherId("#{name}:#{value}") }

      new_item.add_collection(request.collection) if request.collection
      add_rights(item: new_item, pid: pid, request: request, apo: apo_object)

      create_descriptive_metadata(new_item, request)

      new_item.class.ancestors.select { |x| x.respond_to?(:to_class_uri) && x != ActiveFedora::Base }.each do |parent_class|
        new_item.add_relationship(:has_model, parent_class.to_class_uri)
      end

      add_embargo(item: new_item, release_date: request.embargo_release_date, access: request.embargo_access)

      new_item.save!
      new_item
    end

    def create_descriptive_metadata(new_item, request)
      return build_desc_metadata_from_request(new_item, request) if request.metadata_source == 'label'

      refresh_metadata(item: new_item, request: request) if request.seed_desc_metadata

      # Neither of the above scenarios are true for APOs, which rely on Argo to create the descriptive metadata.
    end

    # NOTE: This could fail if Symphony has problems
    def refresh_metadata(item:, request:)
      # This will give us our namespaced identifiers like "catkey:00012032"
      identifiers = request.other_ids.map { |k, v| "#{k}:#{v}" }
      RefreshMetadataAction.run(identifiers: identifiers, datastream: item.descMetadata)
    end

    # add the default rights from the admin policy and any requested rights to the provided item
    def add_rights(item:, pid:, request:, apo:)
      rights_xml = apo.defaultObjectRights.ng_xml
      item.rightsMetadata.content = rights_xml.to_s

      # Rights is not provided for APOs.
      return unless request.rights && %w(item collection).include?(request.object_type)

      item.read_rights = request.rights unless request.rights == 'default' # already defaulted to default!
    end

    def add_embargo(item:, release_date:, access:)
      return unless release_date

      # Based on https://github.com/sul-dlss/hydrus/blob/master/app/models/hydrus/item.rb#L451
      # Except Hydrus has a slightly different model than DOR, so, not setting rightsMetadata.rmd_embargo_release_date
      # item.rightsMetadata.rmd_embargo_release_date = release_date.utc.strftime('%FT%TZ')
      item.embargoMetadata.release_date = release_date
      item.embargoMetadata.status = 'embargoed'

      item.embargoMetadata.release_access_node = Nokogiri::XML(generic_access_xml(access))
      deny_read_access(item.rightsMetadata.ng_xml)
    end

    def deny_read_access(rights_xml)
      rights_xml.search('//rightsMetadata/access[@type=\'read\']').each do |node|
        node.children.remove
        machine_node = Nokogiri::XML::Node.new('machine', rights_xml)
        node.add_child(machine_node)
        machine_node.add_child Nokogiri::XML::Node.new('none', rights_xml)
      end
    end

    def generic_access_xml(access)
      access_xml = access == 'world' ? '<world />' : "<group>#{access}</group>"
      <<-XML
      <releaseAccess>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            #{access_xml}
          </machine>
        </access>
      </embargoAccess>
      XML
    end

    def ids_to_hash(ids)
      return nil if ids.nil?

      Hash[Array(ids).map { |id| id.split(':', 2) }]
    end

    # create basic mods from the request
    def build_desc_metadata_from_request(new_item, request)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(Dor::DescMetadataDS::MODS_HEADER_CONFIG) do
          xml.titleInfo do
            xml.title request.label
          end
          xml.abstract request.abstract if request.abstract.present?
        end
      end
      new_item.descMetadata.content = builder.to_xml
    end
  end
end
# rubocop:enable Metrics/ClassLength
