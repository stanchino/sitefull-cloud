$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RAILS_ENV'] ||= 'test'
if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start do
    add_filter 'version'
  end
end
if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end
require 'aws-sdk'
require 'sitefull-cloud'
Aws.config[:stub_responses] = true
