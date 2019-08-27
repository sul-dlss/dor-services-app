# frozen_string_literal: true

# Responsible for retrieving information based on the given work (Dor::Item).
class ItemQueryService
  # @param [String] id - The id of the work
  # @param [#exists?, #find] work_relation - How we will query some of the related information
  def initialize(id:, work_relation: default_work_relation)
    @id = id
    @work_relation = work_relation
  end

  delegate :allows_modification?, to: :work

  # @raises [RuntimeError] if the item is not modifiable
  def self.find_modifiable_item(druid)
    query_service = ItemQueryService.new(id: druid)
    query_service.work do |work|
      raise "Item #{work.pid} is not open for modification" unless query_service.allows_modification?
    end
  end

  def work(&block)
    @work ||= work_relation.find(id)
    return @work unless block_given?

    @work.tap(&block)
  end

  private

  attr_reader :id, :work_relation

  def default_work_relation
    Dor::Item
  end
end
