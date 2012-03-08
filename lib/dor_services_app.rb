module Dor
  
  class DorServicesApi < Grape::API
    version 'v1'

    resource :dor do        # TODO might have to assume that passenger will route /dor to this app
      resource 'objects/:id' do
      
        # params source can be passed as apended parameter to url:
        #  http://lyberservices-dev/v1/dor/objects/{druid}/initialize_workspace?source=/path/to/content/dir
        # or
        # It can be passed in the body of the request as application/x-www-form-urlencoded parameters, as if submitted from a form
        # TODO: We could get away with loading a simple object that mixes in Dor::Assembleable.  It just needs to implement #pid
        post :initialize_workspace do
          item = Dor::Item.load_instance(params[:id])
          item.initialize_workspace(params[:source])
        end
      
      end
    end
    
  end
  
end