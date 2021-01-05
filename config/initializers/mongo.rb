# frozen_string_literal: true

require 'mongo'

if Settings.enabled_features.mongo
  client_host = if Settings.mongo.srv
                  "mongodb+srv://#{Settings.mongo.username}:#{Settings.mongo.password}@#{Settings.mongo.host}/?retryWrites=true&w=majority"
                else
                  "mongodb://#{Settings.mongo.username}:#{Settings.mongo.password}@#{Settings.mongo.host}:#{Settings.mongo.port}/"
                end

  client = Mongo::Client.new(client_host,
                             max_pool_size: Settings.mongo.max_pool_size).use(Settings.mongo.database)
  collection = client[Settings.mongo.collection.to_sym]

  MongoStore.configure(collection: collection)
  MongoStore.create_indices
end
