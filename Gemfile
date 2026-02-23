source "https://rubygems.org"

ruby "3.3.6"

gem "rails", "~> 8.1.2"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "bcrypt", "~> 3.1"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "solid_cache"
gem "solid_queue"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"
gem "honeybadger", "~> 6.4"
gem "rack-attack", "~> 6.7"

gem "pundit", "~> 2.4"
gem "discard", "~> 1.4"
gem "pagy", "~> 9.3"
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2"
gem "caxlsx", "~> 4.4"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "webmock"
  gem "simplecov", require: false
end
