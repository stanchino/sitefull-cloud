require 'spec_helper'
require 'shared_examples/provider'

RSpec.describe Sitefull::Cloud::Provider, type: :provider do
  before { auth_setup }
  subject { Sitefull::Cloud::Provider.new(type, options) }

  describe 'with type set to Amazon' do
    let(:type) { 'amazon' }
    let(:options) { { token: '{"access_key": "access_key"}', role_arn: 'role', foo: :bar } }
    let(:vpc_id) { 'vpc-id' }
    let(:route_table_id) { 'route-table-id' }
    let(:group_id) { 'group-id' }

    before do
      amazon_auth
      allow_any_instance_of(Aws::EC2::Client).to receive(:run_instances).and_return(double(instances: [double(instance_id: 'instance_id')]))
      allow_any_instance_of(Aws::EC2::Client).to receive(:create_vpc).and_return(double(vpc: double(vpc_id: vpc_id, tags: [])))
      allow_any_instance_of(Aws::EC2::Client).to receive(:describe_route_tables).and_return(double(route_tables: [double(vpc_id: vpc_id, route_table_id: route_table_id, tags: [])]))
      allow_any_instance_of(Aws::EC2::Client).to receive(:describe_security_groups).and_return(double(security_groups: [double(vpc_id: vpc_id, group_id: group_id, tags: [])]))
    end

    it_behaves_like 'cloud provider'

    context 'is valid when there is a dry-run exception' do
      before { allow_any_instance_of(Aws::EC2::Client).to receive(:describe_regions).and_raise(Aws::EC2::Errors::DryRunOperation.new(double, double)) }
      it { expect(subject.valid?).to be_truthy }
    end

    context 'is not valid when there is an error' do
      before { allow_any_instance_of(Aws::EC2::Client).to receive(:describe_regions).and_raise(StandardError) }
      it { expect(subject.valid?).to be_falsey }
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
    let(:options) { { token: '{"access_key": "access_key"}', project_name: project_name } }

    before do
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:get_network).with(project_name, 'sitefull-cloud').and_raise(::Google::Apis::ClientError.new('error'))
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_network).with(project_name, instance_of(::Google::Apis::ComputeV1::Network)).and_return(double(target_link: 'network_id'))
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_firewall).with(project_name, instance_of(::Google::Apis::ComputeV1::Firewall)).and_return(nil)
      allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_instance).with(project_name, :region, instance_of(::Google::Apis::ComputeV1::Instance)).and_return(double(target_link: 'instance_id'))
    end

    it_behaves_like 'cloud provider'

    context 'flavors list is empty on error' do
      before { expect_any_instance_of(::Google::Apis::ComputeV1::ComputeService).to receive(:list_machine_types).and_raise(Google::Apis::ClientError.new('error')) }
      it { expect(subject.flavors(any_args)).to eq [] }
    end

    context 'is not valid when there is an error' do
      before { expect(subject).to receive(:regions).and_raise(StandardError) }
      it { expect(subject.valid?).to be_falsey }
    end

    context 'does not fail if firewall rules cannot be created' do
      before { allow_any_instance_of(Google::Apis::ComputeV1::ComputeService).to receive(:insert_firewall).with(project_name, instance_of(::Google::Apis::ComputeV1::Firewall)).and_raise(Google::Apis::ClientError.new('error')) }
      it { expect(subject.create_firewall_rules(:network_id)).to eq :network_id }
      it { expect { subject.create_firewall_rules(any_args) }.not_to raise_error }
    end
  end

  describe 'with type set to Azure' do
    let(:type) { 'azure' }
    let(:options) { { token: '{"access_key": "access_key"}', role_arn: 'role', foo: :bar } }
    it_behaves_like 'cloud provider'
  end
end
