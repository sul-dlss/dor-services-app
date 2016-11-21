class AssembleableVersionableItem < ActiveFedora::Base
  include Dor::Assembleable
  include Dor::Versionable
  attr_accessor :pid
end
