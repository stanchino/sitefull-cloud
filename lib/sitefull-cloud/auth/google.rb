require 'sitefull-cloud/auth/base'

module Sitefull
  module Auth
    class Google < Base

      AUTHORIZATION_URI = 'https://accounts.google.com/o/oauth2/auth'.freeze
      CALLBACK_URI = '/oauth/google/callback'.freeze
      SCOPE = %w(https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/compute).freeze
      TOKEN_CREDENTIALS_URI = 'https://www.googleapis.com/oauth2/v3/token'.freeze

      def authorization_url_options
        super.merge({ access_type: 'offline', approval_prompt: 'force', include_granted_scopes: true })
      end

      def credentials(token)
        token
      end

      def callback_uri
        CALLBACK_URI
      end

      def authorization_uri(_)
        AUTHORIZATION_URI
      end

      def scope
        SCOPE
      end

      def token_credentials_uri(_)
        TOKEN_CREDENTIALS_URI
      end
    end
  end
end
