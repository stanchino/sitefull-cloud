$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RAILS_ENV'] ||= 'test'
if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
end

require 'sitefull/oauth'
