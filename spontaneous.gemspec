# -*- encoding: utf-8 -*-
require File.expand_path("../lib/spontaneous/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "Spontaneous"
  s.version     = Spontaneous::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = []
  s.email       = []
  s.homepage    = "http://rubygems.org/gems/spontaneous"
  s.summary     = "TODO: Write a gem summary"
  s.description = "TODO: Write a gem description"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "spontaneous"

  s.add_dependency "sequel", "~>3.16"
  s.add_dependency 'mysql2', '~>0.2'
  s.add_dependency "yajl-ruby", "~>0.7"#, :require => 'yajl'
  s.add_dependency "erubis", "~>2.6"
  s.add_dependency "sinatra", "~>1.0"
  # s.add_dependency "shotgun", "0.6"
  # use specific commit with fixes for 1.8.6 until new version is released
  s.add_dependency "rack", :git => "git://github.com/rack/rack.git", :ref => "1598f873c891288954981435e707de26cf49395d" #"~>1.2"
  # s.add_dependency 'rack', '~>1.2'
  s.add_dependency "thin", "~>1.2"
  s.add_dependency "less", "~>1.2"
  s.add_dependency "stringex", "~>1.1"

  s.add_development_dependency "bundler", "~> 1.0.0"

  s.add_development_dependency 'jnunemaker-matchy', '~> 0.4'
  s.add_development_dependency 'shoulda',    '~> 2.10'
  s.add_development_dependency 'timecop',    '~> 0.3'
  s.add_development_dependency 'mocha',      '~> 0.9'
  s.add_development_dependency 'rack-test',  '~> 0.5'
  s.add_development_dependency 'leftright',  '~> 0.9'
  s.add_development_dependency 'stackdeck',  '~> 0.2'

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end

