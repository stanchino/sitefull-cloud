module Sitefull
  module Auth
    class Base

      MISSING_AUTHORIZATION_URI = 'Missing Authorization URL'.freeze
      MISSING_BASE_URI = 'Missing base URL and redirect URL'.freeze
      MISSING_BASE_URI_SCHEME = 'Base URL must be an absolute URL'.freeze
      MISSING_CALLBACK_URI = 'No callback URI specified'.freeze
      MISSING_CLIENT_ID = 'Missing Client ID'.freeze
      MISSING_CLIENT_SECRET = 'Missing Client Secret'.freeze
      MISSING_REDIRECT_URI_SCHEME = 'Redirect URL must be an absolute URL'.freeze
      MISSING_SCOPE = 'Missing scope'.freeze
      MISSING_TOKEN_CREDENTIALS_URI = 'Missing Token Credentials URL'.freeze

      def initialize(options = {})
        @options = validate(options)
      end

      def validate(options = {})
        fail MISSING_CLIENT_ID if options[:client_id].to_s.empty?
        fail MISSING_CLIENT_SECRET if options[:client_secret].to_s.empty?
        fail MISSING_REDIRECT_URI_SCHEME if !options[:redirect_uri].to_s.empty? && URI(options[:redirect_uri].to_s).scheme.to_s.empty?
        process(options)
      end

      def token_options
        @options.select { |k| [:authorization_uri, :client_id, :client_secret, :scope, :token_credential_uri, :redirect_uri].include? k.to_sym }.merge(@options[:token] || {})
      end

      def authorization_url_options
        @options.select { |k| [:state, :login_hint, :redirect_uri].include? k.to_sym }
      end

      def callback_uri
        fail MISSING_CALLBACK_URI
      end

      def authorization_uri
        fail MISSING_AUTHORIZATION_URI
      end

      def scope
        fail MISSING_SCOPE
      end

      def token_credentials_uri
        fail MISSING_TOKEN_CREDENTIALS_URI
      end
      private

      def process(options = {})
        options[:redirect_uri] ||= default_redirect_uri(options) if options[:token].to_s.empty?
        options[:token] = JSON.parse options[:token] unless options[:token].to_s.empty?
        options[:authorization_uri] ||= authorization_uri(options)
        options[:scope] ||= Array(scope)
        options[:token_credential_uri] ||= token_credentials_uri(options)
        options
      end

      def default_redirect_uri(options)
        fail MISSING_BASE_URI if options[:base_uri].to_s.empty?
        fail MISSING_BASE_URI_SCHEME if URI(options[:base_uri].to_s).scheme.to_s.empty?
        URI.join(options[:base_uri].to_s, callback_uri).to_s
      end
    end
  end
end
