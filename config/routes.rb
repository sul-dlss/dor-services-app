# frozen_string_literal: true

require 'sidekiq/web'

# From Sidekiq docs: https://github.com/mperham/sidekiq/wiki/Monitoring#rails-api-application-session-configuration
# Configure Sidekiq-specific session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use Rails.application.config.session_store, Rails.application.config.session_options

Rails.application.routes.draw do
  post '/graphql', to: 'graphql#execute'

  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: 'graphql#execute' if Rails.env.development?

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount Sidekiq::Web => '/queues'

  scope '/v1' do
    get '/about' => 'ok_computer/ok_computer#show', defaults: { check: 'version' }

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
        post 'update_orcid_work'
        post 'accession'
        post 'refresh_metadata', to: 'metadata_refresh#refresh'
        post 'apply_admin_policy_defaults', to: 'admin_policy_defaults#apply'
        post 'reindex'
      end

      collection do
        get 'find'
        post 'versions/status', to: 'versions#batch_status'
      end

      resources :members, only: [:index], defaults: { format: :json }

      resource :query, only: [], defaults: { format: :json } do
        collection do
          get 'collections'
        end
      end

      resource :workspace, only: %i[create destroy]

      resources :events, only: %i[create index], defaults: { format: :json }

      resources :versions, only: %i[create index show] do
        collection do
          get 'openable'
          get 'current'
          delete 'current', action: 'destroy_current'
          get 'status'
          post 'current/close', action: 'close_current'
        end
        member do
          get 'solr'
        end
      end

      resources :user_versions, only: %i[index show create update] do
        member do
          get 'solr'
        end
      end

      resources :release_tags, only: %i[create index]

      resources :workflows, only: %i[index show], controller: 'workflows' do
        member do
          post 'skip_all', to: 'workflows#skip_all'
          post '', to: 'workflows#create'
        end

        resources :processes, only: %i[update], controller: 'workflow_processes'
      end

      resources :lifecycles, only: %i[index], controller: 'workflow_lifecycles'
    end

    resources :workflow_templates, only: %i[index show]
  end
end
