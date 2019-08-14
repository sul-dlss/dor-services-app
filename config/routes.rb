# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

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
      get 'marcxml', to: 'marcxml#marcxml'
      get 'mods', to: 'marcxml#mods'
      get 'catkey', to: 'marcxml#catkey'
    end

    resources :objects, only: [:create, :update] do
      member do
        post 'initialize_workspace', to: 'workspaces#create' # deprecated
        post 'publish'
        post 'update_marc_record'
        post 'notify_goobi'
        post 'release_tags'
        post 'refresh_metadata', to: 'metadata_refresh#refresh'

        get 'contents', to: 'content#list'
        get 'contents/*path', to: 'content#read', format: false, as: :read_content
      end

      resource :workspace, only: [:create, :destroy]

      resources :metadata, only: [] do
        collection do
          get 'dublin_core'
          get 'descriptive'
        end
      end

      resources :versions, only: [:create] do
        collection do
          # TODO: Remove this route in dor-services-app 3.0.0
          get 'openeable', to: 'openeable'
          get 'openable', to: 'openable'
          get 'current'
          post 'current/close', action: 'close_current'
        end
      end
    end
  end
end
