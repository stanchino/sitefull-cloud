require 'azure_mgmt_network'

module Sitefull
  module Provider
    module Azure
      module Networking
        include ::Azure::ARM::Network::Models

        private
        def security_group_setup
          props = NetworkSecurityGroupPropertiesFormat.new

          security_group = NetworkSecurityGroup.new
          security_group.location = options[:region]
          security_group.properties = props

          connection.network.network_security_groups.create_or_update(resource_group_name, SECURITY_GROUP, security_group)
        end

        def network_setup(resource_group, security_group)
          props = VirtualNetworkPropertiesFormat.new

          address_space = AddressSpace.new
          address_space.address_prefixes = [NETWORK_CIDR_BLOCK]
          props.address_space = address_space

          subnet_props = SubnetPropertiesFormat.new
          subnet_props.address_prefix = SUBNET_CIDR_BLOCK
          subnet_props.network_security_group = security_group

          subnet = Subnet.new
          subnet.name = SUBNET_NAME
          subnet.properties = subnet_props
          props.subnets = [subnet]

          params = VirtualNetwork.new
          params.location = options[:region]
          params.properties = props

          connection.network.virtual_networks.create_or_update(resource_group.name, NETWORK_NAME, params)
        end

        def firewall_rule_setup(name, options = {})
          props = SecurityRulePropertiesFormat.new
          options.each { |key, value| props.send("#{key}=", value) }

          security_rule = SecurityRule.new
          security_rule.properties = props

          connection.network.security_rules.create_or_update(resource_group_name, SECURITY_GROUP, name, security_rule)
        end

        def inbound_firewall_rule(name, port, priority)
          firewall_rule_setup(name, protocol: '*', source_port_range: '*', destination_port_range: port, source_address_prefix: '*', destination_address_prefix: '*', priority: priority, access: 'Allow', direction: 'Inbound').value!
        end
      end
    end
  end
end
