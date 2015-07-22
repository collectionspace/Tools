# CSpaceAutomatedTesting

This repository is for automated files written in Gherkin and Ruby with the Cucumber tool, Capybara library, Selenium driver, and other gems (e.g. rspec, capybara-screenshot).

## I. Setting Up
To get started, install the latest versions of Ruby:

1) Install Ruby using the [Ruby Version Manager](https://rvm.io/rvm/install)
```ruby
\curl -L https://get.rvm.io | bash -s stable --ruby
```

2) Install Cucumber and Capybara
```ruby
gem install cucumber
```

```ruby
gem install capybara
```
(Source: Tools and Setting Up sections from http://www.gamesparks.com/blog/automated-testing-with-cucumber-and-capybara/)

3) Install the following gems and other software:

* [capybara-screenshot](https://github.com/mattheworiordan/capybara-screenshot), which is used with Capybara and Cucumber to capture screen shots for every test failure. 

```ruby
gem install capybara-screenshot
```

(Source: https://github.com/mattheworiordan/capybara-screenshot)

* [rspec](https://github.com/rspec/rspec), the behavior-driven development framework for Ruby
```ruby
gem install rspec
```
* [Selenium WebDriver](https://rubygems.org/gems/selenium-webdriver/versions/2.46.2), for automating browsers
```ruby
gem install selenium-webdriver
```

* [Firefox](https://www.mozilla.org/en-US/firefox/new/), is the web browser used to run the tests.

3.5) To avoid using a browser window (aka headless testing), download the [capybara-webkit](https://github.com/thoughtbot/capybara-webkit) gem.

If on Linux platforms, set up a virtual X server (required by capybara-webkit) by either using the xvfb-run utility:
```ruby
xvfb-run -a bundle exec spec
```
Or following [these instructions](https://github.com/leonid-shevtsov/headless) to set up Xvfb 


Then download the capybara-webkit gem 
```ruby
sudo gem install capybara-webkit
```

Finally, uncomment lines 32 - 43 in features/support/env.rb to run cucumber headless.

4) Fork and clone the Tools repository to your local directory

5) Run the tests

* Add the login credentials (e.g. reader or admin; omitting the @xxx) to Tools/qa-webapp-tests/config/environments.yml
* From the qa-webapp-tests directory, run 

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

[Capybara](http://jnicklas.github.io/capybara/) is Ruby gem that drives a browser over the code to run these tests.

[Cucumber](http://cukes.info) is a tool that supports Behavior Driven Development and software testing. It uses the language, Gherkin, to understand user-readable files (features) and parse them into scenarios. These scenarios contain steps that are then matched to the step definitions written in Ruby. 

(Source: https://girliemangalo.wordpress.com/2012/10/29/introduction-to-cucumber/)

## IV. Using Chrome instead of Firefox

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
