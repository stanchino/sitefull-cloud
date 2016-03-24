require 'active_support/dependencies/autoload'

module Sitefull
  module Cloud
    extend ActiveSupport::Autoload
    autoload :Auth, 'sitefull-cloud/auth'
    autoload :Provider, 'sitefull-cloud/provider'
    autoload :Mock, 'sitefull-cloud/mock'

    @mocked = false

    class << self
      attr_reader :mocked
      def mock!
        @mocked = true
      end

      def unmock!
        @mocked = false
      end
    end
  end
end
