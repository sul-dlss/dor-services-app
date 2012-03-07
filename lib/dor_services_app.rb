module Dor
  
  class DorServicesApi < Grape::API
    
    resource :dor do
      
      get :hola do
        "what up"
      end
      
    end
    
  end
  
end