require 'azure_mgmt_network'

module Sitefull
  module Provider
    module Azure
      module Networking
        include ::Azure::ARM::Network::Models

        private
        def security_group_setup

          security_group = NetworkSecurityGroup.new
          security_group.location = options[:region]

          connection.network.network_security_groups.create_or_update(resource_group_name, SECURITY_GROUP, security_group)
        end

        def network_setup(resource_group, security_group)
          address_space = AddressSpace.new
          address_space.address_prefixes = [NETWORK_CIDR_BLOCK]

          subnet = Subnet.new
          subnet.name = SUBNET_NAME
          subnet.address_prefix = SUBNET_CIDR_BLOCK
          subnet.network_security_group = security_group

          params = VirtualNetwork.new
          params.location = options[:region]
          params.address_space = address_space
          params.subnets = [subnet]

          connection.network.virtual_networks.create_or_update(resource_group.name, NETWORK_NAME, params)
        end

        def firewall_rule_setup(name, options = {})
          security_rule = SecurityRule.new
          options.each { |key, value| security_rule.send("#{key}=", value) }

          connection.network.security_rules.create_or_update(resource_group_name, SECURITY_GROUP, name, security_rule)
        end

        def inbound_firewall_rule(name, port, priority)
          firewall_rule_setup(name, protocol: '*', source_port_range: '*', destination_port_range: port, source_address_prefix: '*', destination_address_prefix: '*', priority: priority, access: 'Allow', direction: 'Inbound').value!
        end
      end
    end
  end
end
