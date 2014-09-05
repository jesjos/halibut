source 'https://rubygems.org'

# Specify your gem's dependencies in halibut.gemspec
gemspec

group :travis do
  gem "coveralls"
end

group :testing do
  gem "pry", ">= 0.9.10"

  gem "guard"
  gem "guard-bundler"
  gem "guard-minitest"

  gem "rb-fsevent"
  gem "terminal-notifier-guard"
end

group :script do
  gem "rest-client"
end

platforms 'rbx' do
  gem 'rubysl'
  gem 'rubinius-coverage'
  gem 'rubysl-test-unit'
end
