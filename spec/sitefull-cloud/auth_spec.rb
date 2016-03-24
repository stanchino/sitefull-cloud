require 'spec_helper'
require 'shared_examples/auth'

RSpec.describe Sitefull::Cloud::Auth do
  describe Sitefull::Auth::Base do
    require 'sitefull-cloud/auth/base'

    context 'without callback URI' do
      let(:options) { { client_id: 'client_id', client_secret: 'client_secret', base_uri: 'http://localhost/' } }
      it { expect { Sitefull::Auth::Base.new(options) }.to raise_error(RuntimeError, Sitefull::Auth::Base::MISSING_CALLBACK_URI) }
    end

    context 'without authorization URI' do
      let(:options) { { client_id: 'client_id', client_secret: 'client_secret', redirect_uri: 'http://localhost/oauth/base/callback' } }
      it { expect { Sitefull::Auth::Base.new(options) }.to raise_error(RuntimeError, Sitefull::Auth::Base::MISSING_AUTHORIZATION_URI) }
    end

    context 'without scope' do
      let(:options) { { client_id: 'client_id', client_secret: 'client_secret', redirect_uri: 'http://localhost/oauth/base/callback', authorization_uri: 'http://auth' } }
      it { expect { Sitefull::Auth::Base.new(options) }.to raise_error(RuntimeError, Sitefull::Auth::Base::MISSING_SCOPE) }
    end

    context 'without Token Credentials URI' do
      let(:options) { { client_id: 'client_id', client_secret: 'client_secret', redirect_uri: 'http://localhost/oauth/base/callback', authorization_uri: 'http://auth', scope: 'scope' } }
      it { expect { Sitefull::Auth::Base.new(options) }.to raise_error(RuntimeError, Sitefull::Auth::Base::MISSING_TOKEN_CREDENTIALS_URI) }
    end
  end

  describe 'Amazon' do
    require 'aws-sdk'

    before { allow_any_instance_of(Aws::STS::Client).to receive(:assume_role_with_web_identity).and_return(double(credentials: { access_key_id: :access_key_id, secret_access_key: :secret_access_key, session_token: :session_token })) }
    it_behaves_like 'auth provider with invalid options', :amazon, {}
    it_behaves_like 'auth provider with valid options', :amazon, {role_arn: :role_arn, region: 'region', session_name: 'session_id', redirect_uri: 'http://localhost/oauth/amazon/callback'}
    it_behaves_like 'auth provider with valid options', :amazon, {role_arn: :role_arn, region: 'region', session_name: 'session_id', base_uri: 'http://localhost/'}
    it_behaves_like 'auth provider with valid options', :amazon, {token: '{"access_token": "access_token"}', region: 'region', role_arn: :role_arn, session_name: 'session_id', redirect_uri: 'http://localhost/oauth/amazon/callback'}, true
    it_behaves_like 'auth provider with valid options', :amazon, {token: '{"access_token": "access_token"}', region: 'region', role_arn: :role_arn, session_name: 'session_id', base_uri: 'http://localhost/'}, true
  end

  describe 'Azure' do
    require 'sitefull-cloud/auth/azure'

    it { expect { Sitefull::Cloud::Auth.new(:azure) }.to raise_error(RuntimeError, Sitefull::Auth::Azure::MISSING_TENANT_ID) }
    it_behaves_like 'auth provider with invalid options', :azure, {tenant_id: :tenant_id}
    it_behaves_like 'auth provider with valid options', :azure, {tenant_id: :tenant_id, redirect_uri: 'http://localhost/oauth/azure/callback'}
    it_behaves_like 'auth provider with valid options', :azure, {tenant_id: :tenant_id, base_uri: 'http://localhost/'}
    it_behaves_like 'auth provider with valid options', :azure, {token: '{"access_token": "access_token"}', tenant_id: :tenant_id, redirect_uri: 'http://localhost/oauth/azure/callback'}, true
    it_behaves_like 'auth provider with valid options', :azure, {token: '{"access_token": "access_token"}', tenant_id: :tenant_id, base_uri: 'http://localhost/'}, true
  end

  describe 'Google' do
    it_behaves_like 'auth provider with invalid options', :google, {}
    it_behaves_like 'auth provider with valid options', :google, {redirect_uri: 'http://localhost/oauth/google/callback'}
    it_behaves_like 'auth provider with valid options', :google, {base_uri: 'http://localhost/'}
    it_behaves_like 'auth provider with valid options', :google, {token: '{"access_token": "access_token"}', redirect_uri: 'http://localhost/oauth/google/callback'}, true
    it_behaves_like 'auth provider with valid options', :google, {token: '{"access_token": "access_token"}', base_uri: 'http://localhost/'}, true
  end
end
