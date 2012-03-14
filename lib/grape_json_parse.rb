# Patch to parse json from body of request and set params hash
# https://github.com/intridea/grape/issues/64#issuecomment-3373747
module Grape
  class API
    class << self

      def call(env)
        case env['CONTENT_TYPE']
        when /^application\/json/
          hash = env['rack.input'].read
          parsedForm = JSON.parse(hash) unless hash.blank?
          env.update('rack.request.form_hash' => parsedForm, 'rack.request.form_input' => env['rack.input']) if parsedForm
        end
        logger.info "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
        route_set.freeze.call(env)
      end

    end
  end
end