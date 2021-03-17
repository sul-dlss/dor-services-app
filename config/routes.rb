# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  require 'sidekiq/web'
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
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
      resource :release_tags, only: [:create, :show]
      resources :administrative_tags, only: %i[create update destroy index]

      member do
        post 'publish'
        post 'preserve'
        post 'update_marc_record'
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

      resource :embargo, only: [:update]
      resource :shelve, only: [:create]

      resources :metadata, only: [] do
        collection do
          patch 'legacy', action: :update_legacy_metadata
          get 'dublin_core'
          get 'descriptive'
          get 'mods'
        end
      end

      resources :events, only: [:create, :index], defaults: { format: :json }

      resources :versions, only: [:create] do
        collection do
          get 'openable'
          get 'current'
          post 'current/close', action: 'close_current'
        end
      end
    end
  end
end
