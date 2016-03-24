require 'net/ssh'

module Sitefull
  module Cloud
    class Provider
      include Mock
      PROVIDERS = %w(amazon azure google)

      attr_reader :type, :options

      def initialize(type, options = {})
        @type = type || 'base'
        extend(provider_module)
        @options = respond_to?(:process) ? process(options) : options
      end

      class << self
        def all_required_options
          PROVIDERS.map { |type| required_options_for(type) }.flatten
        end

        def required_options_for(type)
          provider_class(type).const_get(:REQUIRED_OPTIONS)
        end

        def provider_class(type)
          require "sitefull-cloud/provider/#{type}"
          Kernel.const_get "Sitefull::Provider::#{type.capitalize}"
        end
      end

      def auth
        @auth ||= Sitefull::Cloud::Auth.new(type, options)
      end

      protected

      def credentials
        @credentials ||= auth.credentials
      end

      def key_data
        @key_data ||= generate_key_data
      end

      private

      def provider_module
        return self.class.provider_class(:mock) if mocked?
        @provider_module ||= self.class.provider_class(type)
      end

      def generate_key_data
        key = OpenSSL::PKey::RSA.new 2048
        { public_key: [ key.to_blob ].pack('m0'), private_key: key.to_s }
      end
    end
  end
end
