# TODO maybe only include this module if Grape::VERSION == 0.1.5
module Grape
  class Endpoint
    # Override from Grape gem to enable setting of headers in the response
    #
    # End the request and display an error to the
    # end user with the specified message.
    #
    # @param message [String] The message to display.
    # @param status [Integer] the HTTP Status Code.
    def error!(message, status = 403)
      throw :error, :message => message, :status => status, :headers => @header
    end
  end
end
