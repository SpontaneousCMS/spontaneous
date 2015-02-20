Encoding.default_internal = Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spontaneous/version'

require 'rubygems'
require 'rake'

def name
  "spontaneous"
end

def version
  Spontaneous::VERSION
end

#############################################################################
#
# Standard tasks
#
#############################################################################

task :default => :test

require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = 'test/{unit,functional,experimental}/**/test_*.rb'
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
  Rake::TestTask.new(:integration) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/integration/**/test_*.rb'
    test.verbose = true
  end
end


desc "Generate RCov test coverage and open in your browser"
task :coverage do
  require 'rcov'
  sh "rm -fr coverage"
  sh "rcov test/test_*.rb"
  sh "open coverage/index.html"
end

#############################################################################
#
# Packaging tasks
#
#############################################################################

def gemspec_file
  "#{name}.gemspec"
end

def gem_file
  "#{name}-#{version}.gem"
end

namespace :gem do
  desc "Create tag v#{version} and build and push #{gem_file} to Rubygems"
  task :release => :build do
    unless `git branch` =~ /^\* master$/
      puts "You must be on the master branch to release!"
      exit!
    end
    sh "git commit --allow-empty -a -m 'Release #{version}'"
    sh "git tag v#{version}"
    sh "git push origin master"
    sh "git push origin v#{version}"
    sh "gem push pkg/#{gem_file}"
  end

  desc "Build #{gem_file} into the pkg directory"
  task :build do
    sh "gem build #{gemspec_file}"
    sh "mkdir -p pkg"
    sh "mv #{gem_file} pkg"
  end
end

namespace :asset do
  desc "Fingerprints a file"
  task :fingerprint do
    require 'digest/md5'
    unless file = (ENV["file"] || ENV["FILE"])
      puts "Usage rake asset:fingerprint file=path/to/file.ext"
      exit 1
    end
    unless File.file?(file)
      puts "File #{file.inspect} does not exist or is a directory"
      exit 1
    end
    fingerprint = Digest::MD5.file(file).hexdigest
    *name_parts, ext = File.basename(file).split(".")
    name = name_parts.join(".")
    if name =~ /-([0-9a-fA-F]{32})$/
      puts "Removing existing fingerprint '#{$1}'"
      name = name.gsub(/-#{$1}/, "")
    end
    name = "%s-%s.%s" % [name, fingerprint, ext]
    path = File.join File.dirname(file), name
    system "git mv #{file} #{path}"
    p path
  end
end
