require 'rubygems'
require 'bundler'

# Set up the Spontaneous environment
ENV["SPOT_ENV"] = "test"

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$test_glob = nil
if p = ARGV.index('-')
  filenames = ARGV[(p+1)..-1]
  ARGV.slice!((p)..-1)
  $test_glob = filenames.map { |f| "test/**/test_#{f}.rb" }
end

require 'rubygems'
# require 'rake/dsl_definition'
require 'rake'
require 'jeweler'

require File.expand_path("../lib/spontaneous/version", __FILE__)

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "spontaneous"
  gem.homepage    = "http://spontaneouscms.org"
  gem.license = "MIT"
  gem.summary = %Q{TODO: one-line summary of your gem}
  gem.description = %Q{TODO: longer description of your gem}
  gem.email = "garry@magnetised.info"
  gem.authors = ["Garry Hill"]
  gem.version = Spontaneous::VERSION
end
Jeweler::RubygemsDotOrgTasks.new


require 'rake/testtask'


Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = $test_glob || 'test/{unit,slow,functional,experimental}/test_*.rb'
  # test.pattern = $test_glob || 'test/**/test_*.rb'
  test.verbose = false
end

namespace :test do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/unit/**/test_*.rb'
    test.verbose = true
  end

  Rake::TestTask.new(:slow) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/slow/**/test_*.rb'
    test.verbose = true
  end

  Rake::TestTask.new(:functionals) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/functional/**/test_*.rb'
    test.verbose = true
  end
  Rake::TestTask.new(:experimental) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/experimental/**/test_*.rb'
    test.verbose = true
  end
  Rake::TestTask.new(:javascript) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/javascript/**/test_*.rb'
    test.verbose = true
  end
  Rake::TestTask.new(:ui) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/ui/**/test_*.rb'
    test.verbose = true
  end
  Rake::TestTask.new(:js) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/javascript/**/test_*.rb'
    test.verbose = true
  end
end

task :default  => :test
# task :test     => :check_dependencies

# YARD::Rake::YardocTask.new(:doc) do |t|
#   t.options = ["--legacy"] if RUBY_VERSION < "1.9.0"
# end

