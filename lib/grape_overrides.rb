# TODO maybe only include this module if Grape::VERSION == 0.1.5
module Grape
  class Endpoint
    # Override from Grape gem to enable setting of headers in the response 
    # 
    # End the request and display an error to the
    # end user with the specified message.
    #
    # @param message [String] The message to display.
    # @param status [Integer] the HTTP Status Code. Defaults to 403.
    # @param headers [Hash] An optional hash of headers for the response
    def error!(message, status=403, headers = {})
      throw :error, :message => message, :status => status, :headers => headers
    end
  end
  
  module Middleware
    class Error < Base
      
      # Override from Grape gem so that exceptions are logged
      def call!(env)
        @env = env
        
        begin
          error_response(catch(:error){ 
            return @app.call(@env) 
          })
        rescue Exception => e
          raise unless options[:rescue_all] || (options[:rescued_errors] || []).include?(e.class)
          LyberCore::Log.exception(e)
          error_response({ :message => e.message, :backtrace => e.backtrace })
        end
        
      end
    end
  end
end