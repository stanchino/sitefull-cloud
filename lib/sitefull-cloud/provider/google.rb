require 'google/apis/compute_v1'

module Sitefull
  module Provider
    module Google
      REQUIRED_OPTIONS = [:project_name].freeze

      def connection
        return @connection unless @connection.nil?

        connection = ::Google::Apis::ComputeV1::ComputeService.new
        connection.authorization = credentials
        @connection = connection
      end

      def project_name
        @project_name ||= options[:project_name]
      end

      def regions
        @regions ||= connection.list_zones(project_name).items
      end

      def machine_types(zone)
        @machine_types ||= connection.list_machine_types(project_name, zone).items
      rescue ::Google::Apis::ClientError
        []
      end

      def images(os)
        @images ||= project_images(project_name) + project_images("#{os}-cloud")
      end

      def create_network
        return network_id unless network_id.nil?

        network = ::Google::Apis::ComputeV1::Network.new(name: 'sitefull-cloud', i_pv4_range: '172.16.0.0/16')
        connection.insert_network(project_name, network).target_link
      end

      def create_firewall_rules(network_id)
        create_firewall_rule(network_id, 'sitefull-ssh', '22')
        create_firewall_rule(network_id, 'sitefull-http', '80')
        create_firewall_rule(network_id, 'sitefull-https', '443')
        network_id
      end

      def create_key(_name)
        OpenStruct.new(name: :key_name, data: :key_material)
      end

      def create_instance(deployment)
        instance = ::Google::Apis::ComputeV1::Instance.new(name: "sitefull-deployment-#{deployment.id}", machine_type: deployment.machine_type,
                                                           disks: [{ boot: true, autoDelete: true, initialize_params: { source_image: deployment.image } }],
                                                           network_interfaces: [{ network: deployment.network_id, access_configs: [{ name: 'default' }] }])
        connection.insert_instance(project_name, deployment.region, instance).target_link
      end

      def valid?
        regions.any?
      rescue StandardError
        false
      end

      private

      def project_images(project)
        images = connection.list_images(project).items
        images.nil? || images.empty? ? [] : images.reject { |r| !r.deprecated.nil? && r.deprecated.state == 'DEPRECATED' }
      end

      def create_firewall_rule(network_id, rule_name, port)
        rule = ::Google::Apis::ComputeV1::Firewall.new(name: rule_name, source_ranges: ['0.0.0.0/0'], network: network_id, allowed: [{ ip_protocol: 'tcp', ports: [port] }])
        connection.insert_firewall(project_name, rule)
      rescue ::Google::Apis::ClientError
        nil
      end

      def network_id
        @network ||= connection.get_network(project_name, 'sitefull-cloud').self_link
      rescue ::Google::Apis::ClientError
        nil
      end
    end
  end
end
