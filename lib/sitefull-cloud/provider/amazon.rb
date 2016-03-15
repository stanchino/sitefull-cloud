require 'aws-sdk'
require 'sitefull-cloud/provider/amazon/networking'

module Sitefull
  module Provider
    module Amazon
      include Networking

      REQUIRED_OPTIONS = %w(role_arn region session_name).freeze
      MACHINE_TYPES = %w(t2.nano t2.micro t2.small t2.medium t2.large m4.large m4.xlarge m4.2xlarge m4.4xlarge m4.10xlarge m3.medium m3.large m3.xlarge m3.2xlarge).freeze

      DEFAULT_REGION = 'us-east-1'.freeze

      def process(options = {})
        options[:region] ||= DEFAULT_REGION
        options
      end

      def connection
        @connection ||= Aws::EC2::Client.new(region: options[:region], credentials: credentials)
      end

      def regions
        @regions ||= connection.describe_regions.regions.map { |r| OpenStruct.new(id: r.region_name, name: r.region_name) }
      end

      def machine_types(_)
        MACHINE_TYPES.map { |mt| OpenStruct.new(id: mt, name: mt) }
      end

      def images(os)
        filters = [{ name: 'name', values: ["#{os}*", "#{os.downcase}*"] }, { name: 'is-public', values: ['true'] }, { name: 'virtualization-type', values: ['hvm'] }]
        connection.describe_images(filters: filters).images.select { |i| i.image_owner_alias.nil? }.map { |i| OpenStruct.new(id: i.image_id, name: i.name) }
      end

      def create_network
        setup_vpc
        setup_internet_gateway
        setup_routing
        subnet.subnet_id
      end

      def create_key(name)
        result = connection.create_key_pair(key_name: name)
        OpenStruct.new(name: result.key_name, data: result.key_material)
      end

      def create_firewall_rules(_)
        setup_security_group
      end

      # Uses http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Client.html#run_instances-instance_method
      def create_instance(deployment)
        connection.run_instances(image_id: deployment.image, instance_type: deployment.machine_type, subnet_id: deployment.network_id, key_name: deployment.key_name, security_group_ids: [security_group.group_id], min_count: 1, max_count: 1).instances.first.instance_id
      end

      def valid?
        !connection.nil?
      rescue StandardError
        false
      end
    end
  end
end
