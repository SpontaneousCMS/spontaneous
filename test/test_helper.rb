require "rubygems"
require "bundler"
Bundler.setup(:default, :development)

Bundler.require

require 'rack'

begin
  require 'leftright'
rescue LoadError
  # fails for ruby 1.9
end

Sequel.extension :migration

DB = Sequel.connect('mysql2://root@localhost/spontaneous2_test') unless defined?(DB)
Sequel::Migrator.apply(DB, 'db/migrations')

require File.expand_path(File.dirname(__FILE__) + '/../lib/spontaneous')

require 'test/unit'
require 'rack/test'
require 'matchy'
require 'shoulda'
require 'timecop'
require 'mocha'
require 'pp'

require 'support/custom_matchers'
require 'support/timing'


class Test::Unit::TestCase
  include CustomMatchers
end





