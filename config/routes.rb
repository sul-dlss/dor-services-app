# frozen_string_literal: true

require 'sidekiq/web'

# From Sidekiq docs: https://github.com/mperham/sidekiq/wiki/Monitoring#rails-api-application-session-configuration
# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use Rails.application.config.session_store, Rails.application.config.session_options

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount Sidekiq::Web => '/queues'

  scope '/v1' do
    get '/about' => 'ok_computer/ok_computer#show', defaults: { check: 'version' }

    scope :catalog do
      get 'marcxml', to: 'marcxml#marcxml'
      get 'catkey', to: 'marcxml#catkey'
    end

    resources :virtual_objects, only: [:create], defaults: { format: :json }

    resources :background_job_results, only: [:show], defaults: { format: :json }

    resources :administrative_tags, only: [] do
      collection do
        get 'search'
      end
    end

    resources :objects, only: %i[create update destroy show] do
      # NOTE: administrative tags can have dots in the them, so the route needs to accept these
      #  see https://github.com/sul-dlss/argo/issues/2611
      resources :administrative_tags, only: %i[create update destroy index], id: %r{[^/]+}

      member do
        post 'publish'
        post 'preserve'
        post 'update_marc_record'
        post 'update_doi_metadata'
        post 'unpublish'
        post 'notify_goobi'
        post 'accession'
        post 'refresh_metadata', to: 'metadata_refresh#refresh'
        post 'apply_admin_policy_defaults', to: 'admin_policy_defaults#apply'
      end
      resources :members, only: [:index], defaults: { format: :json }

      resource :query, only: [], defaults: { format: :json } do
        collection do
          get 'collections'
        end
      end

      resource :workspace, only: [:create, :destroy] do
        collection do
          post 'reset'
        end
      end

      resource :shelve, only: [:create]

      resource :metadata, only: [] do
        resources :datastreams, only: %i[index show]

        collection do
          patch 'legacy', action: :update_legacy_metadata
          get 'dublin_core'
          get 'descriptive'
          get 'mods'
          get 'public_xml'
        end
      end

      resources :events, only: [:create, :index], defaults: { format: :json }

      resources :versions, only: [:create, :index] do
        collection do
          get 'openable'
          get 'current'
          post 'current/close', action: 'close_current'
        end
      end
    end
  end
end
