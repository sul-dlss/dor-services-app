Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/v1' do
    get '/about' => 'ok_computer/ok_computer#show', defaults: { check: 'version' }
    
    scope '/sdr/objects/:druid' do
      post 'cm-inv-diff', to: 'sdr#cm_inv_diff'
      get 'current_version', to: 'sdr#current_version'
      get 'manifest/:dsname', to: 'sdr#ds_manifest', format: false
      get 'metadata/:dsname', to: 'sdr#ds_metadata', format: false
      get 'content/:filename', to: 'sdr#file_content', format: false
    end
    
    scope '/workflows/:wf_name' do
      get 'initial', to: 'workflows#initial'
    end

    scope :catalog do
      get 'marcxml', to: 'marcxml#marcxml'
      get 'mods', to: 'marcxml#mods'
      get 'catkey', to: 'marcxml#catkey'
    end

    resources :objects, only: [:create] do
      member do
        post 'initialize_workspace'
        post 'publish'
        post 'update_marc_record'
        post 'notify_goobi'
        post 'release_tags'
        post 'apo_workflows/:wf_name', action: 'apo_workflows'

        get 'contents', to: 'content#list'
        get 'contents/*path', to: 'content#read', format: false, as: :read_content
      end
      
      resources :versions, only: [:create] do
        collection do
          get 'current'
          post 'current/close', action: 'close_current'
        end
      end
      
      resources :workflows, only: [] do
        member do
          post 'archive'
          post 'archive/:ver_num', action: :archive
        end
      end
    end
  end
end
