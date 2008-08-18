module EventedNet
  module HTTP
    module Get
      def get(uri, opts = {})
        unless uri.is_a?(URI) && (opts[:callback].is_a?(Proc) || opts[:callback].is_a?(Method)) && opts[:callback].arity == 2
          raise ArgumentError, "uri must be a URI and opts[:callback] must be a Proc (or Method) which takes 2 args"
        end
        EM.reactor_running? ? evented_get(uri, opts) : synchronous_get(uri, opts)
      end
      
      private
        def synchronous_get(uri, opts = {})
          r = Net::HTTP.get_response(uri)
          opts[:callback].call(r.code, r.body)
        end
        
        def evented_get(uri, opts = {})
          http = EM::Protocols::HttpClient.request(
            :host => uri.host, :port => uri.port,
            :request => uri.path, :query => uri.query
          )
          # Make the call back of evented_get, call the user-generated callback
          http.callback { |r| opts[:callback].call(r[:status], r[:content]) }
        end
    end
  end
end