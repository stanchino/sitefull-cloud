require 'forwardable'

module Sitefull
  module Oauth
    class Provider
      extend Forwardable
      def_delegators :@provider, :token_options, :authorization_url_options

      def initialize(provider_type, options = {})
        @token = Signet::OAuth2::Client.new(JSON.parse options[:token]) if options[:token].present?
        @provider = provider_class(provider_type).new(options, options[:token].present?)
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
        token.refresh!
        @credentials ||= @provider.credentials(token)
      end

      private

      def provider_class(provider_type)
        require "sitefull/oauth/#{provider_type}"
        Kernel.const_get "Sitefull::Oauth::#{provider_type.capitalize}"
      end
    end
  end
end
