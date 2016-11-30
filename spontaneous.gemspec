lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spontaneous/version'

Gem::Specification.new do |s|
  s.name          = 'spontaneous'
  s.version       = Spontaneous::VERSION
  s.license       = "MIT"

  s.required_ruby_version = '>= 2.0.0'

  s.summary       = "Next-generation Ruby CMS and web framework."
  s.description   = "Spontaneous is a content management framework that allows the easy development of sophisticated & beautiful websites with powerful developer tools & an elegant editing interface."

  s.authors       = ['Garry Hill']
  s.email         = 'garry@spontaneous.io'
  s.homepage      = 'http://spontaneous.io'

  s.executables   = ['spot']
  s.files         = `git ls-files`.split($/)
  s.test_files    = s.files.grep(%r{^test/})
  s.require_paths = %w[lib]

  s.add_dependency('activesupport',   ['~> 4.0'])
  s.add_dependency('bcrypt',          ['~> 3.1'])
  s.add_dependency('bundler',         ['~> 1.5'])
  s.add_dependency('cutaneous',       ['~> 0.3'])
  s.add_dependency('erubis',          ['~> 2.6'])
  s.add_dependency('fast_blank',      ['~> 1.0'])
  s.add_dependency('fog-core',        ['~> 1.40'])
  s.add_dependency('foreman',         ['~> 0.60'])
  s.add_dependency('kramdown',        ['~> 0.14'])
  s.add_dependency('launchy',         ['~> 2.1'])
  s.add_dependency('mime-types',      ['~> 3.0'])
  s.add_dependency('moneta',          ['~> 0.7'])
  s.add_dependency('nokogiri',        ['~> 1.6'])
  s.add_dependency('posix-spawn',     ['~> 0.3.6'])
  s.add_dependency('public_suffix',   ['~> 1.0'])
  s.add_dependency('rack',            ['~> 1.5'])
  s.add_dependency('rake',            ['~> 10.0'])
  s.add_dependency('sass',            ['~> 3.2'])
  s.add_dependency('sequel',          ['~> 4.8'])
  s.add_dependency('simultaneous',    ['~> 0.5.0'])
  s.add_dependency('sinatra',         ['~> 1.3'])
  s.add_dependency('skeptick',        ['~> 0.1.1'])
  s.add_dependency('sprockets',       ['~> 2.9'])
  s.add_dependency('stringex',        ['=  1.3'])
  s.add_dependency('thin',            ['~> 1.2'])
  s.add_dependency('thor',            ['~> 0.16'])
  s.add_dependency('uglifier',        ['~> 1.3'])
  s.add_dependency('xapian-fu',       ['~> 1.5'])
  # s.add_dependency('oj',              ['~> 2.11'])
  s.add_dependency('yajl-ruby',       ['~> 1.3'])

  s.add_development_dependency('minitest',  ['~> 4.7.0'])
  s.add_development_dependency('minitest-colorize', ['~> 0.0.5'])
  s.add_development_dependency('timecop',   ['~> 0.7'])
  s.add_development_dependency('mocha',     ['~> 0.13.2'])
  s.add_development_dependency('rack-test', ['~> 0.5'])
end
