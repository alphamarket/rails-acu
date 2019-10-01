source 'https://rubygems.org'

ruby '2.6.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Declare your gem's dependencies in acu.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# to fix security bug CVE-2018-3760
gem 'sprockets', '~> 3.7.2'

# To use a debugger
# gem 'byebug', group: [:development, :test]

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'rspec-rails', github: 'rspec/rspec-rails', :tag => "v4.0.0.beta2"
  gem 'sqlite3'
  gem 'awesome_print', github: 'awesome-print/awesome_print'
  gem 'devise'
  gem 'jquery-rails'
  gem 'rails-controller-testing'
end
