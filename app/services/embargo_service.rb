# frozen_string_literal: true

# Sets an embargo for an item.
class EmbargoService
  # @param [Dor::Item] item
  # @param [DateTime] release_date
  # @param [String] access either 'world', 'dark' or a group name
  # @param [String] use_and_reproduction_statement (nil) the use statement to use when the embargo is released
  def self.create(item:, release_date:, access:, use_and_reproduction_statement: nil)
    new(item: item,
        release_date: release_date,
        access: access,
        use_and_reproduction_statement: use_and_reproduction_statement).create
  end

  def initialize(item:, release_date:, access:, use_and_reproduction_statement:)
    @item = item
    @release_date = release_date
    @access = access
    @use_and_reproduction_statement = use_and_reproduction_statement
  end

  def create
    return unless release_date

    # This is set because embargoMetadata datastream is not sent to Purl and
    # sul-embed needs to know this value: https://github.com/sul-dlss/sul-embed/blob/305b3c12924a3de19040e8c96f3335e9e26ce013/app/models/embed/purl.rb#L54
    # In the future we could just write this into the rightsMetadata that is transfered
    # to Purl via the Publish::RightsMetadata service.
    item.rightsMetadata.embargo_release_date = release_date

    item.embargoMetadata.release_date = release_date
    item.embargoMetadata.status = 'embargoed'

    item.embargoMetadata.release_access_node = Nokogiri::XML(generic_access_xml)
    item.embargoMetadata.use_and_reproduction_statement = use_and_reproduction_statement if use_and_reproduction_statement
  end

  private

  attr_reader :item, :release_date, :access, :use_and_reproduction_statement

  def generic_access_xml
    <<-XML
      <releaseAccess>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            #{read_access_xml}
          </machine>
        </access>
      </embargoAccess>
    XML
  end

  def read_access_xml
    case access
    when 'world'
      '<world />'
    when 'dark'
      '<none />'
    else
      "<group>#{access}</group>"
    end
  end
end
