# frozen_string_literal: true

# Monkeypatch to retrieve tags using dor-services-client so that does not need to be run on dor-services-app server.
class AdministrativeTags
  @@tag_cache = {} # rubocop:disable Style/ClassVars

  def self.project(identifier:)
    tag = self.for(identifier: identifier).find { |check_tag| check_tag.start_with?('Project :') }

    return [] unless tag

    [tag.split(' : ', 2).last]
  end

  def self.content_type(identifier:)
    tag = self.for(identifier: identifier).find { |check_tag| check_tag.start_with?('Process : Content Type :') }

    return [] unless tag

    [tag.split(' : ').last]
  end

  def self.for(identifier:)
    cached_tags = @@tag_cache[identifier]
    return cached_tags if cached_tags

    resp = connection.get do |req|
      req.url "v1/objects/#{identifier}/administrative_tags"
    end

    raise "Error getting administrative tags for #{identifier}" unless resp.success?

    tags = JSON.parse(resp.body)

    @@tag_cache[identifier] = tags
    tags
  end

  def self.cache(identifier:, tags:)
    @@tag_cache[identifier] = tags
  end

  # rubocop:disable Style/ClassVars
  def self.connection
    @@connection ||= Faraday.new(Settings.dor_services.url) do |builder|
      builder.use Faraday::Request::UrlEncoded

      builder.adapter Faraday.default_adapter
      builder.headers[:user_agent] = 'fedora-loader'
      builder.headers[:authorization] = "Bearer #{Settings.dor_services.token}"
    end
  end
  # rubocop:enable Style/ClassVars
  private_class_method :connection
end
