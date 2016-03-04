require 'spec_helper'
require 'sitefull-cloud/version'

RSpec.describe Sitefull::Cloud do

  describe 'version' do
    it { expect(Sitefull::Cloud::VERSION).not_to be_nil }
  end
end
