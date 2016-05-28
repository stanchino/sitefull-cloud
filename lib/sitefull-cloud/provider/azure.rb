require 'faraday_middleware'
require 'azure_mgmt_resources'
require 'sitefull-cloud/provider/azure/networking'
require 'sitefull-cloud/provider/azure/instance'

module Sitefull
  module Provider
    module Azure
      extend ActiveSupport
      include ::Azure::ARM::Resources::Models
      include Networking
      include Instance

      REQUIRED_OPTIONS = %w(subscription_id).freeze

      IMAGES = {
        debian: { publisher: 'Credativ', offer: 'Debian' },
        ubuntu: { publisher: 'Canonical', offer: 'UbuntuServer' },
        centos: { publisher: 'OpenLogic', offer: 'CentOS' },
        rhel: { publisher: 'RedHat', offer: 'RHEL' },
        suse: { publisher: 'Suse', offer: 'OpenSUSE' },
        windows_server_2008: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku_filter: '2008' },
        windows_server_2012: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku_filter: '2012' },
        windows_server_2016: { publisher: 'MicrosoftWindowsServer', offer: 'WindowsServer', sku_filter: '2016' }
      }.freeze

      NETWORK_CIDR_BLOCK = '172.16.0.0/16'.freeze
      SUBNET_CIDR_BLOCK = '172.16.1.0/24'.freeze
      NETWORK_NAME = 'sitefull'.freeze
      SUBNET_NAME = 'sitefull'.freeze
      RESOURCE_GROUP = 'sitefull'.freeze
      SECURITY_GROUP = 'sitefull'.freeze
      PUBLIC_IP_NAME = 'sitefull'.freeze

      WAIT = 2.freeze
      SUCCESS_PROVISIONING_STATE = 'Succeeded'.freeze

      def connection
        return @connection unless @connection.nil?

        connections = {
          arm: ::Azure::ARM::Resources::ResourceManagementClient.new(credentials),
          compute: ::Azure::ARM::Compute::ComputeManagementClient.new(credentials),
          network: ::Azure::ARM::Network::NetworkManagementClient.new(credentials),
          storage: ::Azure::ARM::Storage::StorageManagementClient.new(credentials)
        }
        connections.each { |_, v| v.subscription_id = options[:subscription_id] }
        @connection = OpenStruct.new(connections)
      end

      def regions
        @regions ||= connection.arm.providers.get('Microsoft.Compute').resource_types.find { |rt| rt.resource_type == 'virtualMachines' }.locations.map { |l| OpenStruct.new(id: l.downcase.gsub(/\s/, ''), name: l) }
      end

      def machine_types(region)
        @machine_types ||= connection.compute.virtual_machine_sizes.list(region).value.map { |mt| OpenStruct.new(id: mt.name, name: mt.name) }
      end

      def images(os)
        @images unless @images.nil?

        search = IMAGES[os.to_sym]
        image_skus = connection.compute.virtual_machine_images.list_skus(options[:region], search[:publisher], search[:offer])
        @images = image_skus.map { |sku| OpenStruct.new(id: "#{search[:publisher]}:#{search[:offer]}:#{sku.name}", name: "#{search[:offer]} #{sku.name}") }
      end

      def create_network
        resource_group = resource_group_setup
        security_group = security_group_setup.value!.body
        network = network_setup(resource_group, security_group).value!.body
        network.properties.subnets.last.name
      end

      def create_firewall_rules
        inbound_firewall_rule 'ssh', '22', 100
        inbound_firewall_rule 'http', '80', 101
        inbound_firewall_rule 'https', '443', 102
      end

      def create_key(_)
        OpenStruct.new(key_data)
      end

      def create_instance(name, machine_type, image, network_id, key)
        subnet = connection.network.subnets.get(resource_group_name, NETWORK_NAME, network_id)
        security_group = connection.network.network_security_groups.get(resource_group_name, SECURITY_GROUP)
        public_ip = public_ip_setup(name).value!.body
        network_interface = network_interface_setup(subnet, security_group, public_ip, name).value!.body

        storage_setup(name)
        sleep WAIT unless storage_account(name).properties.provisioning_state == SUCCESS_PROVISIONING_STATE
        storage = storage_account(name)

        instance_data = {machine_type: machine_type, image: image, name: name, key: key}
        instance_id = instance_setup(storage, network_interface, instance_data).value!.body.name
        sleep WAIT unless instance(instance_id).properties.provisioning_state == SUCCESS_PROVISIONING_STATE
        instance_id
      end

      def instance_data(instance_id)
        OpenStruct.new(id: instance_id, public_ip: public_ip(instance_id))
      end

      def valid?
        !options[:subscription_id].empty? && !connection.empty? && !regions.empty?
      rescue MsRestAzure::AzureOperationError => e
        raise StandardError.new JSON.parse(e.response.body)['error']['message']
      end

      private

      def resource_group_name
        "#{RESOURCE_GROUP}-#{options[:region]}"
      end

      def resource_group_setup
        resource_group = ResourceGroup.new
        resource_group.location = options[:region]
        connection.arm.resource_groups.create_or_update(resource_group_name, resource_group)
      end
    end
  end
end
