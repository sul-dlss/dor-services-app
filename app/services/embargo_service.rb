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

    embargoMetadata.release_date = release_date
    embargoMetadata.status = 'embargoed'
    embargoMetadata.release_access_node = Nokogiri::XML(generic_access_xml)
    embargoMetadata.use_and_reproduction_statement = use_and_reproduction_statement if use_and_reproduction_statement
  end

  private

  attr_reader :item, :release_date, :access, :use_and_reproduction_statement

  delegate :embargoMetadata, to: :item

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
