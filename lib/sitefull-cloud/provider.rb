module Sitefull
  module Cloud
    class Provider
      attr_reader :type, :options

      def initialize(type, options = {})
        @options = options unless options.nil?
        @type = type || 'base'
        extend(provider_module)
      end

      protected

      def credentials
        @credentials ||= Sitefull::Cloud::Auth.new(type, options).credentials
      end

      private

      def provider_module
        return @provider_module unless @provider_module.nil?
        require "sitefull-cloud/provider/#{@type}"
        @provider_module = Kernel.const_get "Sitefull::Provider::#{@type.capitalize}"
      end
    end
  end
end
