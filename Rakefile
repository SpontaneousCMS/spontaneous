require 'rubygems'
require 'bundler'

# $:.unshift(File.dirname(__FILE__) + '/lib')

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rubygems'
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

  gem.add_dependency "home_run", "~>0.9.4"
  gem.add_dependency "sequel", "~>3.16"
  gem.add_dependency "yajl-ruby", "~>0.7"
  gem.add_dependency "erubis", "~>2.6"
  gem.add_dependency "tenjin", "~> 0.6.1"
  gem.add_dependency 'rack', '~>1.2'
  gem.add_dependency "sinatra", "~>1.0"
  gem.add_dependency "unicorn", "~>2.0.0"
  gem.add_dependency "less", "~>1.2"
  gem.add_dependency "stringex", "~>1.1"
  gem.add_dependency 'miso', '~> 0.3.3'
  gem.add_dependency 'rdiscount', '~> 1.6.5'

  gem.add_development_dependency "bundler", "~> 1.0.0"
  gem.add_development_dependency 'jnunemaker-matchy', '~> 0.4'
  gem.add_development_dependency 'shoulda',    '~> 2.10'
  gem.add_development_dependency 'timecop',    '~> 0.3'
  gem.add_development_dependency 'mocha',      '~> 0.9'
  gem.add_development_dependency 'rack-test',  '~> 0.5'
  gem.add_development_dependency 'leftright',  '~> 0.9'
  gem.add_development_dependency 'stackdeck',  '~> 0.2'
end
Jeweler::RubygemsDotOrgTasks.new


require 'rake/testtask'
$test_glob = nil

if p = ARGV.index('-')
  filenames = ARGV[(p+1)..-1]
  $test_glob = filenames.map { |f| "test/**/test_#{f}.rb" }
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = $test_glob || 'test/**/test_*.rb'
  test.verbose = false
end

namespace :test do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/unit/**/test_*.rb'
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
end

task :default  => :test
# task :test     => :check_dependencies

# YARD::Rake::YardocTask.new(:doc) do |t|
#   t.options = ["--legacy"] if RUBY_VERSION < "1.9.0"
# end

