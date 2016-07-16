require 'spec_helper'
require 'shared_examples/provider'

RSpec.describe Sitefull::Cloud::Provider, type: :provider do
  before { auth_setup }
  subject { Sitefull::Cloud::Provider.new(type, options) }

  describe 'with type set to Amazon' do
    let(:type) { 'amazon' }
    let(:options) { { token: '{"access_key": "access_key"}', client_id: 'client_id', client_secret: 'client_secret', role_arn: 'role', session_name: 'session_id' } }
    let(:vpc_id) { 'vpc-id' }
    let(:route_table_id) { 'route-table-id' }
    let(:group_id) { 'group-id' }
    let(:running_instance) { double(state: double(name: 'running'), public_ip_address: 'ip_address') }

    before do
      amazon_auth
      allow_any_instance_of(Aws::EC2::Client).to receive(:run_instances).and_return(double(instances: [double(instance_id: 'instance_id')]))
      allow_any_instance_of(Aws::EC2::Client).to receive(:create_vpc).and_return(double(vpc: double(vpc_id: vpc_id, tags: [])))
      allow_any_instance_of(Aws::EC2::Client).to receive(:describe_route_tables).and_return(double(route_tables: [double(vpc_id: vpc_id, route_table_id: route_table_id, tags: [])]))
      allow_any_instance_of(Aws::EC2::Client).to receive(:describe_security_groups).and_return(double(security_groups: [double(vpc_id: vpc_id, group_id: group_id, tags: [])]))
      allow_any_instance_of(Aws::EC2::Client).to receive(:describe_instances).and_return(double(reservations: [double(instances: [running_instance])]))
    end

    it_behaves_like 'cloud provider'

    context 'is not valid when there is an error' do
      before { expect(Aws::EC2::Client).to receive(:new).and_raise(StandardError) }
      it { expect { subject.valid? }.to raise_error(StandardError) }
    end

    context 'with existing network gateway' do
      let(:internet_gateway_id) { 'internet-gateway-id' }
      before { allow_any_instance_of(Aws::EC2::Client).to receive(:describe_internet_gateways).and_return(double(internet_gateways: [double(internet_gateway_id: internet_gateway_id, attachments: [double(vpc_id: vpc_id)])])) }

      it 'does not create a new network' do
        expect(subject.create_network).not_to be_nil
        expect(subject).not_to receive(:create_internet_gateway)
      end
    end
  end

  describe 'with type set to Google' do
    let(:project_name) { 'project' }
    let(:type) { 'google' }
    let(:options) { { token: '{"access_key": "access_key"}', client_id: 'client_id', client_secret: 'client_secret', project_name: project_name, region: :region } }

    before do
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:get_network).with(project_name, 'sitefull-cloud').and_raise(::Google::Apis::ClientError.new('error'))
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_network).with(project_name, instance_of(::Google::Apis::ComputeV1::Network)).and_return(double(target_link: 'network_id'))
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:get_firewall).with(project_name, any_args).and_raise(::Google::Apis::ClientError.new('error'))
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_firewall).with(project_name, instance_of(::Google::Apis::ComputeV1::Firewall)).and_return(true)
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_instance).with(project_name, :region, instance_of(::Google::Apis::ComputeV1::Instance)).and_return(double(target_link: 'instance_id'))
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:get_instance).with(project_name, :region, any_args).and_return(double(status: 'CREATING', network_interfaces: [double(access_configs: [double(nat_ip: 'ip_address')])]))
    end

    it_behaves_like 'cloud provider'

    context 'machine types list is empty on error' do
      before { expect_any_instance_of(::Google::Apis::ComputeV1::ComputeService).to receive(:list_machine_types).and_raise(Google::Apis::ClientError.new('error')) }
      it { expect(subject.machine_types(any_args)).to eq [] }
    end

    context 'is not valid when there is an error' do
      before { expect(subject).to receive(:regions).and_raise(StandardError) }
      it { expect { subject.valid? }.to raise_error(StandardError) }
    end
  end

  describe 'with type set to Azure' do
    let(:type) { 'azure' }
    let(:options) { { token: '{"access_key": "access_key"}', client_id: 'client_id', client_secret: 'client_secret', tenant_id: 'tenant_id', subscription_id: 'subscription_id', region: 'westus' } }
    before do
      allow_any_instance_of(::Azure::ARM::Resources::ResourceManagementClient).to receive_message_chain(:resource_groups, :create_or_update).and_return(double(name: 'resource_group'))
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:network_security_groups, :create_or_update, :value!).and_return(double(body: double))
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:virtual_networks, :create_or_update, :value!).and_return(double(body: double(properties: double(subnets: [double(name: 'subnet')]))))
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:security_rules, :create_or_update, :value!).and_return(true)
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:subnets, :get).and_return('subnet')
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:network_security_groups, :get).and_return('security_group')
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:public_ipaddresses, :create_or_update, :value!).and_return(double(body: 'public_ip'))
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:network_interfaces, :create_or_update, :value!).and_return(double(body: 'network_interface'))
      allow_any_instance_of(::Azure::ARM::Network::NetworkManagementClient).to receive_message_chain(:public_ipaddresses, :get).and_return(double(properties: double(ip_address: 'ip_address')))
      allow_any_instance_of(::Azure::ARM::Compute::ComputeManagementClient).to receive_message_chain(:virtual_machines, :get).and_return(double(properties: double(provisioning_state: 'Succeeded')))
      allow_any_instance_of(::Azure::ARM::Compute::ComputeManagementClient).to receive_message_chain(:virtual_machines, :create_or_update, :value!).and_return(double(body: double(name: 'vm')))
    end

    context 'with existing storage account' do
      before do
        allow(subject).to receive(:storage_account_name).with(any_args).and_return 'name'
        allow_any_instance_of(::Azure::ARM::Storage::StorageManagementClient).to receive_message_chain(:storage_accounts, :list_by_resource_group).and_return(double(value: [double(name: 'name', properties: double(provisioning_state: 'Succeeded'))]))
      end

      it_behaves_like 'cloud provider'
    end

    context 'with a missing storage account' do
      before do
        allow(subject).to receive(:storage_account).with(any_args).and_return(nil, double(name: 'name', properties: double(provisioning_state: 'Succeeded')))
        allow_any_instance_of(::Azure::ARM::Storage::StorageManagementClient).to receive_message_chain(:storage_accounts, :create, :value!).and_return(double(body: double(name: 'name')))
      end

      it_behaves_like 'cloud provider'
    end

    context 'is not valid when there is an error' do
      before { expect(subject).to receive(:connection).and_raise(MsRestAzure::AzureOperationError.new(double, double(body: { error: { message: 'message' } }.to_json))) }
      it { expect { subject.valid? }.to raise_error(StandardError) }
    end
  end

  describe 'returns all required options' do
    let(:type) { nil }
    let(:options) { nil }
    let(:expected) { Sitefull::Cloud::Provider::PROVIDERS.map { |provider| Kernel.const_get("Sitefull::Provider::#{provider.capitalize}::REQUIRED_OPTIONS") }.flatten }
    it { expect(subject.class.all_required_options).to match_array expected }
  end
end
