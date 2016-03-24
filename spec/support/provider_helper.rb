module ProviderHelper
  def auth_setup
    allow_any_instance_of(Signet::OAuth2::Client).to receive(:fetch_access_token!).and_return(:token)
  end

  def amazon_auth
    aws_credentials = { access_key_id: 'access_key_id', secret_access_key: 'secret_access_key', session_token: 'session_token' }
    allow_any_instance_of(Aws::STS::Client).to receive(:assume_role_with_web_identity).and_return(double(credentials: aws_credentials))
  end
end
