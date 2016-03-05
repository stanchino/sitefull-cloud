module Sitefull
  module Provider
    module Mock
      def regions
        Array.new(5) { |i| OpenStruct.new(id: "region-id-#{i}", name: "region-name-#{i}") }
      end

      def machine_types(_region)
        Array.new(5) { |i| OpenStruct.new(id: "machine-type-id-#{i}", name: "machine-type-name-#{i}") }
      end

      def images(_os)
        Array.new(5) { |i| OpenStruct.new(id: "image-id-#{i}", name: "image-name-#{i}") }
      end

      def create_network
        'network-id'
      end

      def create_key(name)
        OpenStruct.new(name: name, data: 'key-data')
      end

      def create_firewall_rules(_)
      end

      def create_instance(_)
        'instance-id'
      end

      def valid?
        true
      end
    end
  end
end
