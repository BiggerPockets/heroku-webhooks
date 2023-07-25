source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 7.0.3.1'
gem 'sprockets-rails'

gem 'active_model_serializers', '~> 0.10.10'
gem 'jquery-rails', '>= 4.3.5'
gem 'multi_json'
gem 'omniauth-heroku'
gem 'omniauth-rails_csrf_protection'
gem 'pg', '~> 1.4.1'
gem 'platform-api'
gem 'puma', '~> 5.6.4'
gem 'tzinfo-data'
gem 'uglifier'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'capybara'
  gem 'database_cleaner'
  gem 'dotenv-rails', '>= 2.7.5'
  gem 'launchy'
  gem 'rspec_junit_formatter'
  gem 'rspec-rails', '>= 3.9.1'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

ruby '3.1.2'

gem 'semantic_logger', '~> 4.12'

gem 'net_tcp_client', '~> 2.2'

gem 'rails_semantic_logger', '~> 4.10'

gem 'ddtrace', '~> 1.5'

gem 'amazing_print', '~> 1.4'

gem 'rubocop', '~> 1.54'

gem 'pry-rails', '~> 0.3.9'

gem "dogstatsd-ruby", "~> 5.6"
