require 'spec_helper'
require 'shared_examples/provider'

RSpec.describe Sitefull::Cloud::Provider do
  before { Sitefull::Cloud.mock! }
  after { Sitefull::Cloud.unmock! }
  subject { Sitefull::Cloud::Provider.new(type, {}) }
  context 'for Amazon' do
    let(:type) { :amazon }
    before { expect(Aws::EC2::Client).not_to receive(:new) }
    it_behaves_like 'mocked cloud provider'
  end

  context 'for Google' do
    let(:type) { :google }
    before { expect(Google::Apis::ComputeV1::ComputeService).not_to receive(:new) }
    it_behaves_like 'mocked cloud provider'
  end

  context 'for Azure' do
    let(:type) { :azure }
    it_behaves_like 'mocked cloud provider'
  end
end
