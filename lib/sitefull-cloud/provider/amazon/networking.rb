module Sitefull
  module Provider
    module Amazon
      module Networking
        TEMPLATE_TAG = 'SiteFull Deployment'.freeze
        VPC_CIDR_BLOCK = '172.16.0.0/16'.freeze
        SUBNET_CIDR_BLOCK = '172.16.1.0/24'.freeze

        protected

        def vpc
          @vpc ||= connection.describe_vpcs.vpcs.reverse.find { |v| check_tags(v) } || create_vpc
        end
        alias setup_vpc vpc

        def internet_gateway
          @internet_gateway ||= connection.describe_internet_gateways.internet_gateways.reverse.find { |i| check_internet_gateway(i) } || create_internet_gateway
        end
        alias setup_internet_gateway internet_gateway

        def route_table
          @route_table ||= connection.describe_route_tables.route_tables.reverse.find { |rt| rt.vpc_id == vpc.vpc_id }
        end

        def security_group
          @security_group ||= connection.describe_security_groups.security_groups.reverse.find { |sg| sg.vpc_id == vpc.vpc_id }
        end

        def subnet
          @subnet ||= connection.describe_subnets.subnets.reverse.find { |sg| check_tags(sg) } || create_subnet
        end

        def setup_routing
          add_routing unless check_tags(route_table)
        end

        def setup_security_group
          add_security_group_rules unless check_tags(security_group)
        end

        private

        def create_vpc
          vpc = connection.create_vpc(cidr_block: VPC_CIDR_BLOCK).vpc
          add_tags(vpc.vpc_id)
          vpc
        end

        def check_internet_gateway(internet_gateway)
          internet_gateway.attachments.map(&:vpc_id).include?(vpc.vpc_id)
        end

        def create_internet_gateway
          internet_gateway = connection.create_internet_gateway.internet_gateway
          add_tags(internet_gateway.internet_gateway_id) unless check_tags(internet_gateway)
          connection.attach_internet_gateway(internet_gateway_id: internet_gateway.internet_gateway_id, vpc_id: vpc.vpc_id)
          internet_gateway
        end

        def add_routing
          connection.create_route(route_table_id: route_table.route_table_id, destination_cidr_block: '0.0.0.0/0', gateway_id: internet_gateway.internet_gateway_id)
          add_tags(route_table.route_table_id)
        end

        def add_security_group_rules
          connection.authorize_security_group_ingress(group_id: security_group.group_id, ip_protocol: 'tcp', from_port: 22, to_port: 22, cidr_ip: '0.0.0.0/0')
          add_tags(security_group.group_id)
        end

        def create_subnet
          subnet = connection.create_subnet(vpc_id: vpc.vpc_id, cidr_block: SUBNET_CIDR_BLOCK).subnet
          add_tags(subnet.subnet_id) unless check_tags(subnet)
          connection.modify_subnet_attribute(subnet_id: subnet.subnet_id, map_public_ip_on_launch: { value: true })
          subnet
        end

        def add_tags(resource_id)
          connection.create_tags resources: [resource_id], tags: [{ key: 'Name', value: TEMPLATE_TAG }]
        end

        def check_tags(resource)
          resource.tags.map(&:value).include?(TEMPLATE_TAG)
        end
      end
    end
  end
end
