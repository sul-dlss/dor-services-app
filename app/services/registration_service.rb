# frozen_string_literal: true

# Registers an object. Creates a skeleton object in Fedora with a Druid.
class RegistrationService
  class << self
    # @param [Hash] params
    # @see register_object similar but different
    def create_from_request(params)
      dor_params = registration_request_params(params)

      request = RegistrationRequest.new(dor_params)
      dor_obj = register_object(request)
      pid = dor_obj.pid
      location = URI.parse(Dor::Config.fedora.safeurl.sub(%r{/*$}, '/')).merge("objects/#{pid}").to_s
      dor_params.dup.merge(location: location, pid: pid)
    end

    private

    # Transform the user provided parameters into something suitable to pass to RegistrationRequest
    def registration_request_params(params)
      other_ids = namespace_identifiers(Array(params[:other_id]))
      handle_auto_label(params, other_ids)

      params.slice(:pid, :admin_policy, :label, :object_type, :parent, :seed_datastream, :rights, :metadata_source, :collection)
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
      new_item = request.item_class.new(pid: pid)
      new_item.label = request.label.length > 254 ? request.label[0, 254] : request.label
      idmd = new_item.identityMetadata
      idmd.sourceId = source_id_string
      idmd.add_value(:objectId, pid)
      idmd.add_value(:objectCreator, 'DOR')
      idmd.add_value(:objectLabel, request.label)
      idmd.add_value(:objectType, request.object_type)
      request.other_ids.each_pair { |name, value| idmd.add_otherId("#{name}:#{value}") }
      request.tags.each { |tag| idmd.add_value(:tag, tag) }
      new_item.admin_policy_object = apo_object

      apo_object.administrativeMetadata.ng_xml.xpath('/administrativeMetadata/relationships/*').each do |rel|
        short_predicate = ActiveFedora::RelsExtDatastream.short_predicate rel.namespace.href + rel.name
        if short_predicate.nil?
          ix = 0
          ix += 1 while ActiveFedora::Predicates.predicate_mappings[rel.namespace.href].key?(short_predicate = :"extra_predicate_#{ix}")
          ActiveFedora::Predicates.predicate_mappings[rel.namespace.href][short_predicate] = rel.name
        end
        new_item.add_relationship short_predicate, rel['rdf:resource']
      end
      new_item.add_collection(request.collection) if request.collection
      if request.rights && %w(item collection).include?(request.object_type)
        rights_xml = apo_object.defaultObjectRights.ng_xml
        new_item.datastreams['rightsMetadata'].content = rights_xml.to_s
        new_item.read_rights = request.rights unless request.rights == 'default' # already defaulted to default!
      end
      # create basic mods from the label
      build_desc_metadata_from_label(new_item, request.label) if request.metadata_source == 'label'
      RefreshMetadataAction.run(new_item) if request.seed_desc_metadata

      new_item.class.ancestors.select { |x| x.respond_to?(:to_class_uri) && x != ActiveFedora::Base }.each do |parent_class|
        new_item.add_relationship(:has_model, parent_class.to_class_uri)
      end

      new_item.save
      new_item
    end

    def ids_to_hash(ids)
      return nil if ids.nil?

      Hash[Array(ids).map { |id| id.split(':', 2) }]
    end

    def build_desc_metadata_from_label(new_item, label)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(Dor::DescMetadataDS::MODS_HEADER_CONFIG) do
          xml.titleInfo do
            xml.title label
          end
        end
      end
      new_item.descMetadata.content = builder.to_xml
    end
  end
end
