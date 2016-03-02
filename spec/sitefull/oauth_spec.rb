require 'spec_helper'
require 'shared_examples/provider'
require 'sitefull/oauth'
require 'sitefull/oauth/azure'
require 'aws-sdk'

RSpec.describe Sitefull::Oauth do
  describe Sitefull::Oauth::Base do
    it { expect { subject.callback_uri }.to raise_error(RuntimeError, Sitefull::Oauth::Base::MISSING_CALLBACK_URI) }
  end

  describe 'Google' do
    it_behaves_like 'provider with invalid options', :google, {}
    it_behaves_like 'provider with valid options', :google, {redirect_uri: 'http://localhost/oauth/google/callback'}
    it_behaves_like 'provider with valid options', :google, {base_uri: 'http://localhost/'}
    it_behaves_like 'provider with valid options', :google, {token: '{"access_token": "access_token"}', redirect_uri: 'http://localhost/oauth/google/callback'}, true
    it_behaves_like 'provider with valid options', :google, {token: '{"access_token": "access_token"}', base_uri: 'http://localhost/'}, true
  end

  describe 'Amazon' do
    before { allow_any_instance_of(Aws::STS::Client).to receive(:assume_role_with_web_identity).and_return(double(credentials: { access_key_id: :access_key_id, secret_access_key: :secret_access_key, session_token: :session_token })) }
    it_behaves_like 'provider with invalid options', :amazon, {}
    it_behaves_like 'provider with valid options', :amazon, {role_arn: :role_arn, redirect_uri: 'http://localhost/oauth/amazon/callback'}
    it_behaves_like 'provider with valid options', :amazon, {role_arn: :role_arn, base_uri: 'http://localhost/'}
    it_behaves_like 'provider with valid options', :amazon, {token: '{"access_token": "access_token"}', role_arn: :role_arn, redirect_uri: 'http://localhost/oauth/amazon/callback'}, true
    it_behaves_like 'provider with valid options', :amazon, {token: '{"access_token": "access_token"}', role_arn: :role_arn, base_uri: 'http://localhost/'}, true
  end

  describe 'Azure' do
    it { expect { Sitefull::Oauth::Provider.new(:azure) }.to raise_error(RuntimeError, Sitefull::Oauth::Azure::MISSING_TENANT_ID) }
    it_behaves_like 'provider with invalid options', :azure, {tenant_id: :tenant_id}
    it_behaves_like 'provider with valid options', :azure, {tenant_id: :tenant_id, redirect_uri: 'http://localhost/oauth/azure/callback'}
    it_behaves_like 'provider with valid options', :azure, {tenant_id: :tenant_id, base_uri: 'http://localhost/'}
    it_behaves_like 'provider with valid options', :azure, {token: '{"access_token": "access_token"}', tenant_id: :tenant_id, redirect_uri: 'http://localhost/oauth/azure/callback'}, true
    it_behaves_like 'provider with valid options', :azure, {token: '{"access_token": "access_token"}', tenant_id: :tenant_id, base_uri: 'http://localhost/'}, true
  end
end
