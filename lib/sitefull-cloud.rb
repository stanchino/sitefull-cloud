require 'active_support/dependencies/autoload'

module Sitefull
  module Cloud
    extend ActiveSupport::Autoload
    autoload :Auth, 'sitefull-cloud/auth'
    autoload :Provider, 'sitefull-cloud/provider'
  end
end
