require 'rubygems'
require 'selenium-webdriver'
require 'capybara'
require 'capybara/cucumber'
require 'capybara-screenshot/cucumber'
require File.expand_path('../custom_config', __FILE__)
include CustomConfig

Capybara.default_driver = :selenium
Capybara.default_wait_time = 15

# To override default settings in the capybara-screenshot gem: 
Capybara.save_and_open_page_path = "tmp/capybara"
# To keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

#########################################################################################
# Uncomment below to use the Selenium webdriver with 'headless'
# Note that this only works for Linux machines due to X graphics.
#########################################################################################
# if Capybara.current_driver == :selenium
#   require 'headless'
#   headless = Headless.new
#   headless.start
# end

#########################################################################################
# Uncomment below to use the Poltergeist webdriver. 
# Tested successfully on OS X and Linux.
#########################################################################################
require 'capybara/poltergeist'
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, :timeout => 45)
end
Capybara.default_driver = :poltergeist

#########################################################################################
# Uncomment below to use the capybara-webkit webdriver.
# Tested on OS X and Linux but requires changing some of the test suites. 
# More info at README.md 
#########################################################################################  
# require 'capybara-webkit'
# Capybara::Webkit.configure do |config|
#   config.allow_unknown_urls
#   config.timeout = 45
# end
# Capybara.default_driver = :webkit

##########################################################################
# Uncomment the code below to run tests on chrome. More info at README.md
##########################################################################
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, :browser => :chrome)
# end
# Capybara.javascript_driver = :chrome

World(Capybara)