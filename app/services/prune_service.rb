# frozen_string_literal: true

# Removes the druid path from the filesystem
class PruneService
  # @param [DruidTools::Druid] druid
  def initialize(druid:)
    @druid = druid
  end

  def prune!
    this_path = druid.pathname
    parent = this_path.parent
    parent.rmtree if parent.exist? && parent != druid.base_pathname
    prune_ancestors parent.parent
  end

  # @param [Pathname] outermost_branch The branch at which pruning begins
  # @return [void] Ascend the druid tree and prune empty branches
  # @raises [Errno::ENOENT] if the directory does not exist
  def prune_ancestors(outermost_branch)
    while outermost_branch.exist? && outermost_branch.children.empty?
      outermost_branch.rmdir
      outermost_branch = outermost_branch.parent
      break if outermost_branch == druid.base_pathname
    end
  end

  private

  attr_reader :druid
end
