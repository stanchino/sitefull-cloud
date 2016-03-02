require 'sitefull/cloud/base'

module Sitefull
  module Cloud
    class Google < Base

      AUTHORIZATION_URI = 'https://accounts.google.com/o/oauth2/auth'.freeze
      CALLBACK_URI = '/oauth/google/callback'.freeze
      SCOPE = %w(https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/compute).freeze
      TOKEN_CREDENTIALS_URI = 'https://www.googleapis.com/oauth2/v3/token'.freeze

      def initialize(options = {}, skip_validation = false)
        @options = skip_validation ? options : validate(options)
      end

      def validate(options = {})
        options = super(options)
        options[:authorization_uri] ||= AUTHORIZATION_URI
        options[:scope] ||= Array(SCOPE)
        options[:token_credential_uri] ||= TOKEN_CREDENTIALS_URI
        options
      end

      def token_options
        @options.select { |k| [:authorization_uri, :client_id, :client_secret, :scope, :token_credential_uri, :redirect_uri].include? k.to_sym }
      end

      def authorization_url_options
        @options.select { |k| [:state, :login_hint, :redirect_uri].include? k.to_sym }.merge({ access_type: 'offline', approval_prompt: 'force', include_granted_scopes: true })
      end

      def credentials(token)
        token
      end

      def callback_uri
        CALLBACK_URI
      end
    end
  end
end
