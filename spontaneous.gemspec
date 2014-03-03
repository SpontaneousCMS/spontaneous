lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spontaneous/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.3'

  s.name          = 'spontaneous'
  s.version       = Spontaneous::VERSION

  s.summary       = "Spontaneous is a next-generation Ruby CMS"
  s.description   = "Spontaneous is a next-generation Ruby CMS"

  s.authors       = ['Garry Hill']
  s.email         = 'garry@spontaneous.io'
  s.homepage      = 'http://spontaneous.io'

  s.executables   = ['spot']
  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^test/})
  s.require_paths = %w[lib]

  s.rdoc_options  = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[LICENSE]

  # s.signing_key   = '/Volumes/Keys/rubygems-garry-magnetised-net-private_key.pem'
  # s.cert_chain    = ['gem-public_cert.pem']

  s.add_dependency('activesupport',   ['~> 4.0'])
  s.add_dependency('coffee-script',   ['~> 2.2'])
  s.add_dependency('bcrypt-ruby',     ['~> 3.0'])
  s.add_dependency('bundler',         ['>  1.0'])
  s.add_dependency('cutaneous',       ['~> 0.2'])
  s.add_dependency('erubis',          ['~> 2.6'])
  s.add_dependency('fog',             ['~> 1.17'])
  s.add_dependency('foreman',         ['~> 0.60'])
  s.add_dependency('kramdown',        ['~> 0.14'])
  s.add_dependency('launchy',         ['~> 2.1'])
  s.add_dependency('moneta',          ['~> 0.7'])
  s.add_dependency('nokogiri',        ['~> 1.5'])
  s.add_dependency('posix-spawn',     ['~> 0.3.6'])
  s.add_dependency('public_suffix',   ['~> 1.0'])
  s.add_dependency('rack',            ['~> 1.5'])
  s.add_dependency('rake',            ['~> 0.9'])
  s.add_dependency('sass',            ['~> 3.2'])
  s.add_dependency('sequel',          ['~> 3.43'])
  s.add_dependency('simultaneous',    ['~> 0.4.2'])
  s.add_dependency('sinatra',         ['~> 1.3'])
  s.add_dependency('skeptick',        ['~> 0.1'])
  s.add_dependency('sprockets',       ['~> 2.9'])
  s.add_dependency('stringex',        ['=  1.3'])
  s.add_dependency('thin',            ['~> 1.2'])
  s.add_dependency('thor',            ['~> 0.16'])
  s.add_dependency('uglifier',        ['~> 1.3'])
  s.add_dependency('xapian-fu',       ['~> 1.5'])
  s.add_dependency('yajl-ruby',       ['~> 1.1'])

  s.add_development_dependency('minitest',  ['~> 4.7.0'])
  s.add_development_dependency('minitest-colorize', ['~> 0.0.5'])
  s.add_development_dependency('mocha',     ['~> 0.13.2'])
  s.add_development_dependency('rack-test', ['~> 0.5'])
end
