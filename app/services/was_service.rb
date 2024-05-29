# frozen_string_literal: true

# Helpers for Web Archiving Service (WAS)
class WasService
  def self.crawl?(druid:)
    WorkflowClientFactory.build.workflows(druid).include?('wasCrawlPreassemblyWF')
  end
end
