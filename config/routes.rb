# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  require 'sidekiq/web'
  Sidekiq::Web.set :session_secret, Rails.application.credentials[:secret_key_base]
  mount Sidekiq::Web => '/queues'

  scope '/v1' do
    get '/about' => 'ok_computer/ok_computer#show', defaults: { check: 'version' }

    scope '/sdr/objects/:druid' do
      post 'cm-inv-diff', to: 'sdr#cm_inv_diff'
      get 'current_version', to: 'sdr#current_version'
      get 'manifest/:dsname', to: 'sdr#ds_manifest', format: false, constraints: { dsname: /.+/ }
      get 'metadata/:dsname', to: 'sdr#ds_metadata', format: false, constraints: { dsname: /.+/ }
      get 'content/:filename', to: 'sdr#file_content', format: false, constraints: { filename: /.+/ }
    end

    scope :catalog do
      get 'catkey', to: 'marcxml#catkey'
    end

    resources :virtual_objects, only: [:create]

    # TODO: Remove :update once Argo, in stage and prod, uses a version of dor-services-client that no longer hits this endpoint
    resources :objects, only: [:create, :update, :show] do
      member do
        post 'publish'
        post 'update_marc_record'
        post 'notify_goobi'
        post 'release_tags'
        post 'refresh_metadata', to: 'metadata_refresh#refresh'

        get 'contents', to: 'content#list'
        get 'contents/*path', to: 'content#read', format: false, as: :read_content
      end

      resource :query, only: [], defaults: { format: :json } do
        collection do
          get 'collections'
        end
      end

      resource :workspace, only: [:create, :destroy]
      resource :embargo, only: [:update]

      resources :metadata, only: [] do
        collection do
          get 'dublin_core'
          get 'descriptive'
        end
      end

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
