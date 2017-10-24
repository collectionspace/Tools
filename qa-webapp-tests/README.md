# CSpaceAutomatedTesting

This repository is for automated files written in Gherkin and Ruby with the Capybara library, Selenium driver, and other gems (e.g. rspec, capybara-screenshot).

## I. Setting Up
To get started, install the latest versions of Ruby:

1) Install Ruby using the [Ruby Version Manager](https://rvm.io/rvm/install)
```ruby
\curl -L https://get.rvm.io | bash -s stable --ruby
```

2) Install Cucumber and Capybara
```ruby
gem install cucumber
gem install capybara
```
(Source: Tools and Setting Up sections from http://www.gamesparks.com/blog/automated-testing-with-cucumber-and-capybara/)

3) Additional Installations:
* [rspec](https://github.com/rspec/rspec), the behavior-driven development framework for Ruby
* [Selenium WebDriver](https://rubygems.org/gems/selenium-webdriver/versions/2.46.2), for automating browsers
* [capybara-screenshot](https://github.com/mattheworiordan/capybara-screenshot), which is used with Capybara and Cucumber to capture screen shots for every test failure. 

```ruby
gem install rspec
gem install selenium-webdriver
gem install capybara-screenshot
```

* Install [Firefox](https://www.mozilla.org/en-US/firefox/new/), the web browser used to run the tests.

4) Fork and clone the Tools repository to your local directory

5) Initialize the environment variables
* In Tools/qa-webapp-tests/config create an environments.yml file using the format of sample_environments.yml.
* In Tools/qa-webapp-tests/config/environments.yml:
    - Set 'login' and 'password' to your user credentials but omitting the @xxx.xxx for 'login' (e.g. if the login is sample@cspace.berkeley.edu, set 'login': sample)
    - Set the 'server' variable to "" for prod or "-dev" for dev

6) Run the tests
From the qa-webapp-tests directory, run 

```ruby
cucumber features/[featurename].feature
```
To run all test cases:
```ruby 
cucumber features/
```

The results are in this format:

> 1 scenario (1 passed)

> 10 steps (10 passed)

> 0m7.492s


## II. Repo Structure
Here is a brief overview of the repository structure:

```ruby
qa-webapp-tests

    >> features
    
        *location of all feature files*
        
        >> step_definitions
        
            *location of all step definition Ruby files*

        >> support
        
            *location of configuration files, e.g. env.rb*
```     

Features describe the frontend components that users interact with. 
Step definitions describe the user actions for each step. Multiple step definitions make up a feature.


## III. About the Tools

[Capybara](http://jnicklas.github.io/capybara/) is a library written in Ruby that simulates how a user would interact with an app. 

[Cucumber](http://cukes.info) is a tool that interprets plain-text descriptions as automated tests and allows testers to write tests in human-readable format. Cucumber scripts are parsed by Gherkin into scenarios. These scenarios contain steps that are matched to the step definitions written in Ruby. 

(Source: https://girliemangalo.wordpress.com/2012/10/29/introduction-to-cucumber/)

## IV. Running Tests Headless

There are currently three options for headless testing (without browser GUI), and it depends on which web driver you wish to use to test.

1 **Selenium with headless** (Best option, Robust, Linux Only):

Install Xvfb and headless gem
```ruby
sudo apt-get install xvfb
sudo gem install headless
```

Set up a virtual X server by either using the xvfb-run utility:
```ruby
xvfb-run -a bundle exec spec
```
Or following [these instructions](https://github.com/leonid-shevtsov/headless) to set up Xvfb / QI (** for Linux platforms only)

Finally, uncomment lines 23 - 27 in features/support/env.rb to run cucumber headless.

2 **Poltergeist with PhantomJS** (Fastest Performance):

First install phantomjs through the [website](https://code.google.com/p/phantomjs/downloads/list). Then download and extract.

Alternatively, **if OS X**:
```ruby
brew install phantomjs
```
However it may take a long time as it will download the Qt library. It may be best to download qt beforehand using homebrew:
```ruby
brew install qt
```
**If Linux**:
```ruby
sudo apt-get install phantomjs
```
------------------------------------------------------  

Then install the [poltergeist](https://github.com/teampoltergeist/poltergeist) gem using ruby:
```ruby
sudo gem install poltergeist
```
Finally uncomment lines 36-41 in features/support/env.rb to run cucumber headless.

3 **Capybara Web-kit**

Use capybara-webkit only if you can't get the above two options working and want to run headless testing. Using this driver requires you to modify test suites.

Download the [capybara-webkit](https://github.com/thoughtbot/capybara-webkit) gem.

The capybara-webkit gem 
```ruby
sudo gem install capybara-webkit
```
Finally, uncomment lines 52 - 57 in features/support/env.rb to run cucumber headless with capybara web-kit.

## V. Using Chrome instead of Firefox

To change the default browser selenium runs from Firefox to Chrome, first download chromedriver using either homebrew 
```ruby
brew install chromedriver
```
or through their [website](https://sites.google.com/a/chromium.org/chromedriver/).

Then, for the feature you want to run with chrome, add a @javascript tag in the line before Scenario. For example, if we want to use chrome for features/pahma_search.feature, inside we add:
```ruby
Feature: Find and use the keyword search feature of the PAHMA development server.

@javascript
Scenario: Search for the website    
```
