namespace :valkyrie do
  desc "Import resources to valkyie"
  task import: :environment do
    Dor::Item.all.each do |item|
      puts "Item: #{item.pid}"
      model = Cocina::Mapper.build(item)
      Orm::Resource.create
    end
  end
end
