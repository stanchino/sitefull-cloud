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

      REQUIRED_OPTIONS = %w(region subscription_id).freeze

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
        @regions ||= connection.arm.providers.get('Microsoft.Compute').value!.body.resource_types.find { |rt| rt.resource_type == 'virtualMachines' }.locations.map { |l| OpenStruct.new(id: l.downcase.gsub(/\s/, ''), name: l) }
      end

      def machine_types(region)
        @machine_types ||= connection.compute.virtual_machine_sizes.list(region).value!.body.value.map { |mt| OpenStruct.new(id: mt.name, name: mt.name) }
      end

      def images(os)
        @images unless @images.nil?

        search = IMAGES[os.to_sym]
        image_skus = connection.compute.virtual_machine_images.list_skus(options[:region], search[:publisher], search[:offer]).value!.body
        @images = image_skus.map { |sku| OpenStruct.new(id: "#{search[:publisher]}:#{search[:offer]}:#{sku.name}", name: "#{search[:offer]} #{sku.name}") }
      end

      def create_network
        resource_group = resource_group_setup.value!.body
        security_group = security_group_setup.value!.body
        network = network_setup(resource_group, security_group).value!.body
        network.properties.subnets.last.name
      end

      def create_firewall_rules(_)
        inbound_firewall_rule 'ssh', '22', 100
        inbound_firewall_rule 'http', '80', 101
        inbound_firewall_rule 'https', '443', 102
      end

      def create_key(key_name)
        OpenStruct.new(name: key_name, data: {})
      end

      def create_instance(deployment)
        name = "sitefull-deployment-#{deployment.id}"
        subnet = connection.network.subnets.get(resource_group_name, NETWORK_NAME, SUBNET_NAME).value!.body
        security_group = connection.network.network_security_groups.get(resource_group_name, SECURITY_GROUP).value!.body
        public_ip = public_ip_setup(name).value!.body
        network_interface = network_interface_setup(subnet, security_group, public_ip, name).value!.body
        storage = storage_setup(name)
        instance_setup(storage, network_interface, deployment.machine_type, deployment.image, name).value!.body.name
      end

      def valid?
        !connection.empty?
      rescue StandardError
        false
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

      def image_skus
      end
    end
  end
end
