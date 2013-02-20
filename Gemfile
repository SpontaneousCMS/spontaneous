source "https://rubygems.org"

gemspec

gem 'selenium-client', '~> 1.2.18', :platforms => [:mri_18]
gem 'mocha', :require => false

# group :development do
#   # gem 'Selenium', '~> 1.1.14'
# end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'jdbc-postgres'
  gem 'jdbc-mysql'
end

platforms :mri do
  gem 'mysql2', "~> 0.3.11"
  gem 'pg',     "~> 0.14.1"
  gem 'xapian-ruby', "~> 1.2.12"
  gem 'xapian-fu', "~> 1.3"
end
