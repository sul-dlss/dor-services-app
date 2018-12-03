# RDF 1.99 requires HAML 4, which depends on ActionView::Template::Handlers::Erubis
# however, this class is not provided by Rails 5.2.  So we'll provide it here.
# NOTE: This patch must be in place prior to calling Bundler.require (config/application.rb)

# rubocop:disable Style/ClassAndModuleChildren
class ActionView::Template::Handlers::Erubis; end
# rubocop:enable Style/ClassAndModuleChildren
