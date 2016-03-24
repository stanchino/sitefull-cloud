module Sitefull
  module Provider
    module Mock
      def regions
        mock_list 'region'
      end

      def machine_types(_region)
        mock_list 'machine-type'
      end

      def images(_os)
        mock_list 'image'
      end

      def create_network
        'network-id'
      end

      def create_key(_name)
        OpenStruct.new(ssh_user: 'ssh_user', public_key: 'public_key', private_key: 'private_key')
      end

      def create_firewall_rules
      end

      def create_instance(_, _, _, _, _)
        'instance-id'
      end

      def valid?
        true
      end

      private
      def mock_list(prefix)
        Array.new(5) { |i| OpenStruct.new(id: "#{prefix}-id-#{i}", name: "#{prefix}-name-#{i}") }
      end
    end
  end
end
