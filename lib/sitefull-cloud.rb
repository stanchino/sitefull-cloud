require 'active_support/dependencies/autoload'

module Sitefull
  module Cloud
    extend ActiveSupport::Autoload
    autoload :Auth, 'sitefull-cloud/auth'
  end
end
