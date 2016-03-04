RSpec.shared_examples 'cloud provider' do
  describe 'and generates a list of regions' do
    it { expect(subject.regions).not_to be_empty }
  end

  describe 'and generates a list of flavors' do
    it { expect(subject.flavors(any_args)).not_to be_empty }
  end

  describe 'and generates a list of images' do
    it { expect(subject.images('debian')).not_to be_empty }
  end

  describe 'and is valid?' do
    it { expect(subject.valid?).to be_truthy }
  end

  describe 'and has the correct type' do
    it { expect(subject.instance_variable_get(:@type)).to eq type }
  end

  describe 'and creates a network' do
    it { expect(subject.create_network).not_to be_nil }
  end

  describe 'and creates firewall rules' do
    it { expect(subject.create_firewall_rules(any_args)).not_to be_nil }
  end

  describe 'and creates a key' do
    it { expect(subject.create_key(:key_name)).not_to be_nil }
  end

  describe 'and creates an instance' do
    it { expect(subject.create_instance(double(id: :id, region: :region, image: :image, flavor: :flavor, network_id: :network_id, key_name: :key_name))).not_to be_nil }
  end

  describe 'without type' do
    let(:type) { nil }
    let(:options) { nil }
    [:regions, :flavors].each do |method|
      context "returns an empty list for #{method}" do
        it { expect(subject.send(method)).to eq [] }
      end
    end
    context 'returns an empty array for images' do
      it { expect(subject.images(any_args)).to eq [] }
    end
    context 'is not valid' do
      it { expect(subject.valid?).to be_falsey }
    end
  end
end
