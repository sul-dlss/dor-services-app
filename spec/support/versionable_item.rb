class VersionableItem < ActiveFedora::Base
  include Dor::Versionable
  attr_accessor :pid
end
