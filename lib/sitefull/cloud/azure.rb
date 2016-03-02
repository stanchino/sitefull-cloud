require 'sitefull/cloud/base'
require 'ms_rest/credentials/token_provider'
require 'ms_rest/credentials/string_token_provider'
require 'ms_rest/credentials/service_client_credentials'
require 'ms_rest/credentials/token_credentials'

module Sitefull
  module Cloud
    class Azure < Base

      AUTHORIZATION_URI = 'https://login.microsoftonline.com/%s/oauth2/authorize'.freeze
      CALLBACK_URI = '/oauth/azure/callback'.freeze
      SCOPE = %w(https://management.core.windows.net/).freeze
      TOKEN_CREDENTIALS_URI = 'https://login.microsoftonline.com/%s/oauth2/token'.freeze

      MISSING_TENANT_ID = 'Missing Tenant ID'.freeze

      def initialize(options = {}, skip_validation = false)
        @options = skip_validation ? options : validate(options)
      end

      def validate(options = {})
        fail MISSING_TENANT_ID if options[:tenant_id].nil? || options[:tenant_id].to_s.empty?
        options = super(options)
        options[:authorization_uri] ||= sprintf(AUTHORIZATION_URI, options[:tenant_id])
        options[:scope] ||= Array(SCOPE)
        options[:token_credential_uri] ||= sprintf(TOKEN_CREDENTIALS_URI, options[:tenant_id])
        options
      end

      def token_options
        @options.select { |k| [:authorization_uri, :client_id, :client_secret, :scope, :token_credential_uri, :redirect_uri].include? k.to_sym }
      end

      def authorization_url_options
        @options.select { |k| [:state, :login_hint, :redirect_uri].include? k.to_sym }.merge({ resource: 'https://management.core.windows.net/'})
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
