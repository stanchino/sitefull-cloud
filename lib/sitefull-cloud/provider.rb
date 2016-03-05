module Sitefull
  module Cloud
    class Provider
      include Mock
      PROVIDERS = %w(amazon azure google)

      attr_reader :type, :options

      def initialize(type, options = {})
        @options = options unless options.nil?
        @type = type || 'base'
        extend(provider_module)
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

      protected

      def credentials
        @credentials ||= Sitefull::Cloud::Auth.new(type, options).credentials
      end

      private

      def provider_module
        return self.class.provider_class(:mock) if mocked?
        @provider_module ||= self.class.provider_class(type)
      end
    end
  end
end
