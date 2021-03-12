# frozen_string_literal: true

# Validator for MODS.
class ModsValidator
  include Dry::Monads[:result]

  # @param [Nokogiri::Document] ng_xml
  # @return [Dry::Monads::Result]
  def self.valid?(ng_xml)
    new(ng_xml).valid?
  end

  def initialize(ng_xml)
    @ng_xml = ng_xml
  end

  def valid?
    mods_version = ng_xml.root[:version]
    return Failure(['MODS version attribute not found.']) if mods_version.nil?

    Dir.chdir('mods') do
      mods_xsd_filename = "mods-#{mods_version.sub('.', '-')}.xsd"
      return Failure(['Unknown MODS version.']) unless File.exist?(mods_xsd_filename)

      xsd = Nokogiri::XML::Schema(File.read(mods_xsd_filename))
      return Success() if xsd.valid?(ng_xml)

      Failure(xsd.validate(ng_xml).map(&:to_s))
    end
  end

  private

  attr_reader :ng_xml
end
