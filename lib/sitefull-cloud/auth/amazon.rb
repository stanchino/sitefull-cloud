require 'sitefull-cloud/auth/base'
require 'aws-sdk'

module Sitefull
  module Auth
    class Amazon < Base

      AUTHORIZATION_URI = 'https://www.amazon.com/ap/oa'.freeze
      CALLBACK_URI = '/oauth/amazon/callback'.freeze
      SCOPE = %w(profile).freeze
      TOKEN_CREDENTIALS_URI = 'https://api.amazon.com/auth/o2/token'.freeze
      PROVIDER_ID = 'www.amazon.com'.freeze

      MISSING_ROLE_ARN = 'Missing Role ARN'.freeze
      MISSING_REGION = 'Missing Region'.freeze
      MISSING_SESSION_NAME = 'Missing session name'.freeze

      def credentials(token)
        fail MISSING_ROLE_ARN if @options[:role_arn].to_s.empty?
        fail MISSING_REGION if @options[:region].to_s.empty?
        fail MISSING_SESSION_NAME if @options[:session_name].to_s.empty?

        sts = Aws::STS::Client.new(region: @options[:region])
        response = sts.assume_role_with_web_identity(role_arn: @options[:role_arn],
                                                     role_session_name: @options[:session_name],
                                                     provider_id: 'www.amazon.com',
                                                     web_identity_token: token.access_token)
        Aws::Credentials.new(*response.credentials.to_h.values_at(:access_key_id, :secret_access_key, :session_token))
      end

      def validate(options = {})
        options = super(options)
        options[:authorization_uri] ||= AUTHORIZATION_URI
        options[:scope] ||= Array(SCOPE)
        options[:token_credential_uri] ||= TOKEN_CREDENTIALS_URI
        options
      end

      def callback_uri
        CALLBACK_URI
      end
    end
  end
end

