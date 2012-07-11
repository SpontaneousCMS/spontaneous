# Load Spontaneous specific deployment tasks
%w(deploy sync).each do |task|
  load File.expand_path("../capistrano/#{task}.rb", __FILE__)
end

# Fix for ActiveSupport breaking Capistrano's #capture method.
# See this thread:
# https://github.com/capistrano/capistrano/issues/168
Capistrano::Configuration::Namespaces::Namespace.class_eval do
  def capture(*args)
    parent.capture *args
  end
end
