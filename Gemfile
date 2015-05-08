source "https://rubygems.org"

gemspec

gem 'selenium-client', '~> 1.2', :platforms => [:mri_18]
gem 'mocha', :require => false

gem 'therubyracer',    '~> 0.11'

gem 'pry'
gem 'pry-doc'

# group :development do
#   # gem 'Selenium', '~> 1.1.14'
# end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'jdbc-postgres'
  gem 'jdbc-mysql'
  gem 'jdbc-sqlite3'
end

platforms :mri, :rbx do
  gem 'mysql2',      '~> 0.3'
  gem 'sequel_pg',   '~> 1.6', require: 'sequel'
  gem 'xapian-ruby', '~> 1.2'
  gem 'sqlite3',     '~> 1.3'
end


platforms :rbx do
  gem 'rubysl', '~> 2.0'
end