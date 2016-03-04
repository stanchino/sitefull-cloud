module Sitefull
  module Provider
    module Azure
      REQUIRED_OPTIONS = [:subscription_id].freeze

      def connection
        #       @connection ||= {
        #         arm: ::Azure::ARM::Resources::ResourceManagementClient.new(credentials),
        #         net: ::Azure::ARM::Network::NetworkResourceProviderClient.new(credentials),
        #         compute: ::Azure::ARM::Compute::ComputeManagementClient.new(credentials)
        #       }
      end

      def regions
        ['us']
      end

      def flavors(region)
        ["machine-type-#{region}"]
      end

      def images(os)
        ["image-region-#{os}"]
      end

      def create_network
        'network_id'
      end

      def create_firewall_rules(network_id)
        network_id
      end

      def create_key(key_name)
        OpenStruct.new(name: key_name, data: {})
      end

      def create_instance(deployment)
        deployment
      end

      def valid?
        true
      end
    end
  end
end
