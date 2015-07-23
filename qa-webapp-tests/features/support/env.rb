require 'rubygems'
#require 'headless'
require 'selenium-webdriver'
require 'capybara'
require 'capybara/cucumber'
require 'capybara-screenshot/cucumber'

require File.expand_path('../custom_config', __FILE__)
include CustomConfig
Capybara.default_driver = :selenium
Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Capybara.default_driver = :selenium
Capybara.default_wait_time = 15

# To override default settings in the capybara-screenshot gem: ###
Capybara.save_and_open_page_path = "tmp/capybara"
# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

##################################################################
# Uncomment the code below to run tests without a browser window #
##################################################################
# Headless.ly do
#   driver = Selenium::WebDriver.for :firefox
#   driver.navigate.to 'http://google.com'
#   puts driver.title 
# end

# if Capybara.current_driver == :selenium
#   require 'headless'

#   headless = Headless.new
#   headless.start
# end

World(Capybara)

##################################################################
# Uncomment the code below to run tests on chrome. Read README.md
##################################################################
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, :browser => :chrome)
# end

# Capybara.javascript_driver = :chrome