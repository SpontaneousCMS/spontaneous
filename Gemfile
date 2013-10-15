source "https://rubygems.org"

gemspec

gem 'selenium-client', '~> 1.2.18', :platforms => [:mri_18]
gem 'mocha', :require => false

gem 'therubyracer',    '~> 0.11.1'

# group :development do
#   # gem 'Selenium', '~> 1.1.14'
# end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'jdbc-postgres'
  gem 'jdbc-mysql'
end

platforms :mri, :rbx do
  gem 'mysql2',      '~> 0.3.11'
  gem 'pg',          '~> 0.14.1'
  gem 'xapian-ruby', '~> 1.2.12'
end


platforms :rbx do
  gem 'rubysl', '~> 2.0'
end