# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'rspec/core/rake_task'
require 'pact/tasks'

$LOAD_PATH << './lib'

RSpec::Core::RakeTask.new(:spec)
task :default => [:spec, 'pact:verify']

desc 'Run the client'
task :run_client do
  require 'client'
  Client.base_uri 'localhost:8081'
  Client.new.process_data
end
