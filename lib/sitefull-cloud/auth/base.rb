module Sitefull
  module Auth
    class Base

      MISSING_BASE_URI = 'Missing base URL and redirect URL'.freeze
      MISSING_BASE_URI_SCHEME = 'Base URL must be an absolute URL'.freeze
      MISSING_CALLBACK_URI = 'No callback URI specified'.freeze
      MISSING_CLIENT_ID = 'Missing Client ID'.freeze
      MISSING_CLIENT_SECRET = 'Missing Client Secret'.freeze
      MISSING_REDIRECT_URI_SCHEME = 'Redirect URL must be an absolute URL'.freeze

      def validate(options = {})
        fail MISSING_CLIENT_ID if options[:client_id].to_s.empty?
        fail MISSING_CLIENT_SECRET if options[:client_secret].to_s.empty?
        fail MISSING_REDIRECT_URI_SCHEME if !options[:redirect_uri].to_s.empty? && URI(options[:redirect_uri].to_s).scheme.to_s.empty?
        options[:redirect_uri] ||= default_redirect_uri(options)
        options
      end

      def callback_uri
        fail MISSING_CALLBACK_URI
      end

      private

      def default_redirect_uri(options)
        fail MISSING_BASE_URI if options[:base_uri].to_s.empty?
        fail MISSING_BASE_URI_SCHEME if URI(options[:base_uri].to_s).scheme.to_s.empty?
        URI.join(options[:base_uri].to_s, callback_uri).to_s
      end
    end
  end
end
