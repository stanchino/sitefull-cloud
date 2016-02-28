require 'sitefull/oauth/base'

module Sitefull
  module Oauth
    class Amazon < Base

      AUTHORIZATION_URI = 'https://www.amazon.com/ap/oa'.freeze
      CALLBACK_URI = '/oauth/amazon/callback'.freeze
      SCOPE = %w(profile).freeze
      TOKEN_CREDENTIALS_URI = 'https://api.amazon.com/auth/o2/token'.freeze
      PROVIDER_ID = 'www.amazon.com'.freeze

      MISSING_ROLE_ARN = 'Missing Role ARN'.freeze

      def initialize(options = {})
        @options = validate(options) || {}
      end

      def credentials(token)
        fail MISSING_ROLE_ARN unless @options[:role_arn].present?
        sts = Aws::STS::Client.new(region: 'us-east-1')
        response = sts.assume_role_with_web_identity(role_arn: @options[:role_arn],
                                                     role_session_name: @options[:session_name],
                                                     provider_id: 'www.amazon.com',
                                                     web_identity_token: token.access_token)
        Aws::Credentials.new(*response.credentials.to_h.values_at(:access_key_id, :secret_access_key, :session_token))
      end

      def validate(options = {})
        options = super(options.symbolize_keys)
        options[:authorization_uri] ||= AUTHORIZATION_URI
        options[:scope] ||= Array(SCOPE)
        options[:token_credential_uri] ||= TOKEN_CREDENTIALS_URI
        options[:session_name] ||= 'web-user-session'
        options
      end

      def token_options
        @options.extract!(:authorization_uri, :client_id, :client_secret, :scope, :token_credential_uri, :redirect_uri)
      end

      def authorization_url_options
        @options.extract!(:state, :login_hint, :redirect_uri)
      end

      def callback_uri
        CALLBACK_URI
      end
    end
  end
end

