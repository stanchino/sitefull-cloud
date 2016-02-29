$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RAILS_ENV'] ||= 'test'
if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start do
    add_filter 'version'
  end
end
require 'aws-sdk'
Aws.config[:stub_responses] = true
