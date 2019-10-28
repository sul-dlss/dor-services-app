# frozen_string_literal: true

namespace :valkyrie do
  desc 'Import resources to valkyie'
  task import: :environment do
    Dor::Item.all.each do |item|
      model = Cocina::Mapper.build(item)
      item.contentMetadata.resource.each do |resource|
        puts resource
        fileset = Cocina::Models::FileSet.new
        Orm::Resource.create(metadata: fileset.as_json, resource_type: 'FileSet')
      end
      Orm::Resource.create(metadata: model.as_json, resource_type: item.class)
    end
  end
end
