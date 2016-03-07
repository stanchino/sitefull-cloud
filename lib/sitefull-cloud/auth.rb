require 'signet/oauth_2/client'
require 'forwardable'

module Sitefull
  module Cloud
    class Auth
      extend Forwardable
      def_delegators :@auth, :token_options, :authorization_url_options

      def initialize(auth_type, options = {})
        @auth = auth_class(auth_type).new(options)
      end

      def authorization_url
        token.authorization_uri(authorization_url_options)
      end

      def authorize!(code)
        token.code = code
        token.fetch_access_token!
      end

      def token
        @token ||= Signet::OAuth2::Client.new(token_options)
      end

      def credentials
        return @credentials unless @credentials.nil?
        token.refresh!
        @credentials = @auth.credentials(token)
      end

      private

      def auth_class(auth_type)
        require "sitefull-cloud/auth/#{auth_type}"
        Kernel.const_get "Sitefull::Auth::#{auth_type.capitalize}"
      end
    end
  end
end
