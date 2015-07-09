require 'capybara/cucumber'
require 'capybara-screenshot/cucumber'
Capybara.default_driver = :selenium

# Ignore for now: testing to override default Firefox browser w/ Chrome
# Capybara.register_driver :chrome do |app|
#   Capybara::Selenium::Driver.new(app, :browser => :chrome)
# end

# Capybara.javascript_driver = :chrome


# Uncomment line below if you want to override the wait time
Capybara.default_wait_time = 10

# Capybara.save_and_open_page_path = "tmp/capybara"

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run
# Uncomment below if you want to keep up to the number of screenshots specified in the hash
# Capybara::Screenshot.prune_strategy = { keep: 20 }
