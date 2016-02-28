module Sitefull
  module Oauth
    class Base

      MISSING_BASE_URL = 'Missing base URL and redirect URL'.freeze
      MISSING_BASE_URL_SCHEME = 'Base URL must be an absolute URL'.freeze
      MISSING_CALLBACK_URI = 'No callback URI specified'.freeze
      MISSING_CLIENT_ID = 'Missing Client ID'.freeze
      MISSING_CLIENT_SECRET = 'Missing Client Secret'.freeze
      MISSING_REDIRECT_URL_SCHEME = 'Redirect URL must be an absolute URL'.freeze

      def validate(options = {})
        fail MISSING_CLIENT_ID unless options[:client_id]
        fail MISSING_CLIENT_SECRET unless options[:client_secret]
        fail MISSING_REDIRECT_URL_SCHEME unless options[:redirect_url].blank? || URI(options[:redirect_url]).scheme.present?
        options[:redirect_uri] ||= default_redirect_uri(options)
        options
      end

      def callback_uri
        fail MISSING_CALLBACK_URI
      end

      private

      def default_redirect_uri(options)
        fail MISSING_BASE_URL if options[:base_url].nil?
        fail MISSING_BASE_URL_SCHEME if URI(options[:base_url]).scheme.nil?
        URI.join(options[:base_url], callback_uri).to_s
      end
    end
  end
end
