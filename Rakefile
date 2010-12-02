$:.unshift(File.dirname(__FILE__) + '/lib')


require 'rubygems'
require 'rake'
# require 'jeweler'
# require 'yard'
# require 'yard/rake/yardoc_task'

# Jeweler::Tasks.new do |gem|
#   gem.name        = "spontaneous"
#   gem.summary     = %Q{CMF}
#   gem.email       = "garry@magnetised.info"
#   gem.homepage    = "http://magnetised.info/spontaneous"
#   gem.authors     = ["Garry Hill"]
#   
#   # gem.add_dependency('mongo_mapper', '>= 0.6.8')
#   # gem.add_dependency('activesupport', '>= 2.3')
#   # gem.add_dependency('erubis', '>= 2.6')
#   # gem.add_dependency('mongo', '0.18.2')
#   # gem.add_dependency('jnunemaker-validatable', '1.8.1')
#   
#   gem.add_development_dependency('jnunemaker-matchy', '0.4.0')
#   gem.add_development_dependency('shoulda', '2.10.2')
#   gem.add_development_dependency('timecop', '0.3.1')
#   gem.add_development_dependency('mocha', '0.9.8')
# end
# 
# Jeweler::GemcutterTasks.new

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

