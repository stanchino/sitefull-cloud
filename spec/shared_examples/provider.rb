require 'sitefull/oauth/base'
require 'signet/oauth_2/client'

RSpec.shared_examples 'provider with invalid options' do |provider, options|
  let(:invalid_options) { options.merge({client_id: :client_id, client_secret: :client_secret}) }
  let(:invalid_redirect_uri_options) { options.merge({client_id: :client_id, client_secret: :client_secret, redirect_uri: :redirect_uri}) }
  let(:invalid_base_uri_options) { options.merge({client_id: :client_id, client_secret: :client_secret, base_uri: :base_uri}) }

  it { expect { Sitefull::Oauth::Provider.new(provider, invalid_options.reject { |k| k == :client_id }) }.to raise_error(RuntimeError, Sitefull::Oauth::Base::MISSING_CLIENT_ID) }
  it { expect { Sitefull::Oauth::Provider.new(provider, invalid_options.reject { |k| k == :client_secret }) }.to raise_error(RuntimeError, Sitefull::Oauth::Base::MISSING_CLIENT_SECRET) }
  it { expect { Sitefull::Oauth::Provider.new(provider, invalid_options.reject { |k| k == :base_uri || k == :redirect_uri}) }.to raise_error(RuntimeError, Sitefull::Oauth::Base::MISSING_BASE_URI) }
  it { expect { Sitefull::Oauth::Provider.new(provider, invalid_redirect_uri_options) }.to raise_error(RuntimeError, Sitefull::Oauth::Base::MISSING_REDIRECT_URI_SCHEME) }
  it { expect { Sitefull::Oauth::Provider.new(provider, invalid_base_uri_options) }.to raise_error(RuntimeError, Sitefull::Oauth::Base::MISSING_BASE_URI_SCHEME) }
end

RSpec.shared_examples 'provider with valid options' do |provider, options, skip_authorization_url_check|
  let(:valid_options) { options.merge({client_id: :client_id, client_secret: :client_secret}) }

  context 'initialize' do
    it { expect { Sitefull::Oauth::Provider.new(provider, valid_options) }.not_to raise_error }
  end

  describe 'methods' do
    subject { Sitefull::Oauth::Provider.new(provider, valid_options) }

    unless skip_authorization_url_check
      context 'generates authorization URL' do
        it { expect(subject.authorization_url).not_to be_nil }
      end
    end

    context 'generates a token' do
      it { expect(subject.token).not_to be_nil }
      it { expect(subject.token).to be_a Signet::OAuth2::Client }
    end

    context 'authorizes the token by code' do
      before { expect_any_instance_of(Signet::OAuth2::Client).to receive(:fetch_access_token!).and_return(:token) }
      it { expect(subject.authorize!(:code)).to eq :token }
    end

    context 'generates credentials' do
      before { expect_any_instance_of(Signet::OAuth2::Client).to receive(:refresh!) }
      it { expect(subject.credentials).not_to be_nil }
    end
  end
end
