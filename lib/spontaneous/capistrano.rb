# Load Spontaneous specific deployment tasks
%w(deploy sync).each do |task|
  load File.expand_path("../capistrano/#{task}.rb", __FILE__)
end
