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

    # Based on https://github.com/sul-dlss/hydrus/blob/master/app/models/hydrus/item.rb#L451
    # Except Hydrus has a slightly different model than DOR, so, not setting rightsMetadata.rmd_embargo_release_date
    # item.rightsMetadata.rmd_embargo_release_date = release_date.utc.strftime('%FT%TZ')
    deny_read_access
    item.rightsMetadata.embargo_release_date = release_date

    item.embargoMetadata.release_date = release_date
    item.embargoMetadata.status = 'embargoed'

    item.embargoMetadata.release_access_node = Nokogiri::XML(generic_access_xml)
    item.embargoMetadata.use_and_reproduction_statement = use_and_reproduction_statement if use_and_reproduction_statement
  end

  private

  attr_reader :item, :release_date, :access, :use_and_reproduction_statement

  def deny_read_access
    rights_xml = item.rightsMetadata.ng_xml
    rights_xml.search('//rightsMetadata/access[@type=\'read\']').each do |node|
      node.children.remove
      machine_node = Nokogiri::XML::Node.new('machine', rights_xml)
      node.add_child(machine_node)
      machine_node.add_child Nokogiri::XML::Node.new('none', rights_xml)
    end
    item.rightsMetadata.ng_xml_will_change!
  end

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
