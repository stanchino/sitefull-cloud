RSpec.configure do |config|
  config.before(:each) do
    [
      [:regions, Array(5).map { |i| OpenStruct.new(id: "region-id-#{i}", name: "region-name-#{i}") }],
      [:machine_types, Array(5).map { |i| OpenStruct.new(id: "machine-type-id-#{i}", name: "machine-type-name-#{i}") }],
      [:images, Array(5).map { |i| OpenStruct.new(id: "image-id-#{i}", name: "image-name-#{i}") }],
      [:create_network, 'network_id'],
      [:create_key, OpenStruct.new(id: 'key-id', name: 'key-name', data: 'key-data')],
      [:create_firewall_rules, nil],
      [:create_instance, 'instance-id'],
      [:valid?, true]
    ].each do |method, data|
      allow_any_instance_of(Sitefull::Cloud::Provider).to receive(method).and_return(data)
    end
    allow(Sitefull::Cloud::Auth).to receive(:new).and_return(double(credentials: :credentials))
  end
end
