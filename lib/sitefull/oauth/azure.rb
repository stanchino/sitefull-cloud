require 'sitefull/oauth/base'

module Sitefull
  module Oauth
    class Azure < Base

      AUTHORIZATION_URI = 'https://login.microsoftonline.com/%s/oauth2/authorize'.freeze
      CALLBACK_URI = '/oauth/azure/callback'.freeze
      SCOPE = %w(https://management.core.windows.net/).freeze
      TOKEN_CREDENTIALS_URI = 'https://login.microsoftonline.com/%s/oauth2/token'.freeze

      MISSING_TENANT_ID = 'Missing Tenant ID'.freeze

      def initialize(options = {})
        fail MISSING_TENANT_ID unless options[:tenant_id].present?
        @options = validate(options) || {}
      end

      def validate(options = {})
        options = super(options.symbolize_keys)
        options[:authorization_uri] ||= sprintf(AUTHORIZATION_URI, options[:tenant_id])
        options[:scope] ||= Array(SCOPE)
        options[:token_credential_uri] ||= sprintf(TOKEN_CREDENTIALS_URI, options[:tenant_id])
        options
      end

      def token_options
        @options.extract!(:authorization_uri, :client_id, :client_secret, :scope, :token_credential_uri, :redirect_uri)
      end

      def authorization_url_options
        @options.extract!(:state, :login_hint, :redirect_uri).merge({ resource: 'https://management.core.windows.net/'})
      end

      def credentials(token)
        token_provider = MsRest::StringTokenProvider.new(token.access_token)
        MsRest::TokenCredentials.new(token_provider)
      end

      def callback_uri
        CALLBACK_URI
      end
    end
  end
end
