# encoding: utf-8

require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => [:spec, 'pact:tests']

task :init do
  $:.unshift 'lib'
end

desc 'Run the client'
task :run_client => :init do
  require 'client'
  require 'ap'
  Client.new.process_data
end
