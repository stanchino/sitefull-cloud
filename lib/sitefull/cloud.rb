require 'forwardable'

module Sitefull
  module Cloud
    class Provider
      extend Forwardable
      def_delegators :@provider, :token_options, :authorization_url_options

      def initialize(provider_type, options = {})
        token_set = !options[:token].to_s.empty?
        token(JSON.parse options[:token]) if token_set
        @provider = provider_class(provider_type).new(options, token_set)
      end

      def authorization_url
        token.authorization_uri(authorization_url_options)
      end

      def authorize!(code)
        token.code = code
        token.fetch_access_token!
      end

      def token(token_data = nil)
        @token ||= Signet::OAuth2::Client.new(token_data.nil? ? token_options : token_data)
      end

      def credentials
        token.refresh!
        @credentials ||= @provider.credentials(token)
      end

      private

      def provider_class(provider_type)
        require "sitefull/cloud/#{provider_type}"
        Kernel.const_get "Sitefull::Cloud::#{provider_type.capitalize}"
      end
    end
  end
end
