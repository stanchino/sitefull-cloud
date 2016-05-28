require 'google/apis/compute_v1'
Google::Apis::RequestOptions.default.retries = 5

module Sitefull
  module Provider
    module Google
      REQUIRED_OPTIONS = %w(project_name).freeze

      WAIT = 2.freeze
      INSTANCE_RUNNING_STATE = 'RUNNING'.freeze

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
        @regions ||= connection.list_zones(project_name).items.map { |r| OpenStruct.new(id: r.name, name: r.name) }
      end

      def machine_types(zone)
        @machine_types ||= connection.list_machine_types(project_name, zone).items.map { |m| OpenStruct.new(id: m.self_link, name: m.name) }
      rescue ::Google::Apis::ClientError
        []
      end

      def images(os)
        @images ||= (project_images(project_name) + project_images("#{os}-cloud")).map { |i| OpenStruct.new(id: i.self_link, name: i.name) }
      end

      def create_network
        return network_id unless network_id.nil?

        network = ::Google::Apis::ComputeV1::Network.new(name: 'sitefull-cloud', i_pv4_range: '172.16.0.0/16')
        connection.insert_network(project_name, network).target_link
      end

      def create_firewall_rules
        create_firewall_rule(network_id, 'sitefull-ssh', '22')
        create_firewall_rule(network_id, 'sitefull-http', '80')
        create_firewall_rule(network_id, 'sitefull-https', '443')
      end

      def create_key(_)
        OpenStruct.new(key_data)
      end

      def create_instance(name, machine_type, image, network_id, key)
        instance = ::Google::Apis::ComputeV1::Instance.new(name: name, machine_type: machine_type,
                                                           disks: [{ boot: true, autoDelete: true, initialize_params: { source_image: image } }],
                                                           network_interfaces: [{ network: network_id, access_configs: [{ name: 'default' }] }],
                                                           metadata: { items: [{ key: 'ssh-keys', value: "#{key.ssh_user}:ssh-rsa #{key.public_key} #{key.ssh_user}"}] })
        connection.insert_instance(project_name, options[:region], instance).target_link
        sleep WAIT unless instance(name).status == INSTANCE_RUNNING_STATE
        name
      end

      def instance_data(instance_id)
        OpenStruct.new(id: instance_id, public_ip: instance(instance_id).network_interfaces.first.access_configs.first.nat_ip)
      end

      def valid?
        regions.any?
      end

      private

      def project_images(project)
        images = connection.list_images(project).items
        images.nil? || images.empty? ? [] : images.reject { |r| !r.deprecated.nil? && r.deprecated.state == 'DEPRECATED' }
      end

      def create_firewall_rule(network_id, rule_name, port)
        return if firewall_rule_exists?(rule_name)
        rule = ::Google::Apis::ComputeV1::Firewall.new(name: rule_name, source_ranges: ['0.0.0.0/0'], network: network_id, allowed: [{ ip_protocol: 'tcp', ports: [port] }])
        connection.insert_firewall(project_name, rule)
      end

      def firewall_rule_exists?(rule_name)
        connection.get_firewall(project_name, rule_name)
      rescue ::Google::Apis::ClientError
        false
      end

      def network_id
        @network ||= connection.get_network(project_name, 'sitefull-cloud').self_link
      rescue ::Google::Apis::ClientError
        nil
      end

      def instance(instance_id)
        connection.get_instance(project_name, options[:region], instance_id)
      end
    end
  end
end
