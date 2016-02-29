require 'spec_helper'
require 'sitefull/oauth/version'

RSpec.describe Sitefull::Oauth do

  describe 'version' do
    it { expect(Sitefull::Oauth::VERSION).not_to be_nil }
  end
end
