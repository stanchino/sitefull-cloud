require 'sitefull-cloud/auth/base'
require 'ms_rest/credentials/token_provider'
require 'ms_rest/credentials/string_token_provider'
require 'ms_rest/credentials/service_client_credentials'
require 'ms_rest/credentials/token_credentials'

module Sitefull
  module Auth
    class Azure < Base

      AUTHORIZATION_URI = 'https://login.microsoftonline.com/%s/oauth2/authorize'.freeze
      CALLBACK_URI = '/oauth/azure/callback'.freeze
      SCOPE = %w(https://management.core.windows.net/).freeze
      TOKEN_CREDENTIALS_URI = 'https://login.microsoftonline.com/%s/oauth2/token'.freeze

      MISSING_TENANT_ID = 'Missing Tenant ID'.freeze

      def validate(options = {})
        fail MISSING_TENANT_ID if options[:tenant_id].nil? || options[:tenant_id].to_s.empty?
        super(options)
      end

      def authorization_url_options
        super.merge({ resource: 'https://management.core.windows.net/'})
      end

      def credentials(token)
        token_provider = MsRest::StringTokenProvider.new(token.access_token)
        MsRest::TokenCredentials.new(token_provider)
      end

      def callback_uri
        CALLBACK_URI
      end

      def authorization_uri(options)
        sprintf(AUTHORIZATION_URI, options[:tenant_id])
      end

      def scope
        SCOPE
      end

      def token_credentials_uri(options)
        sprintf(TOKEN_CREDENTIALS_URI, options[:tenant_id])
      end
    end
  end
end
