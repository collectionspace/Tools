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

4) Fork and clone the Tools repository to your local directory

5) Initialize the environment variables
* In Tools/qa-webapp-tests/config create an environments.yml file in format of sample_environments.yml.
* In Tools/qa-webapp-tests/config/environments.yml:
	- Set 'login' and 'password' to your user credentials but omitting the @xxx.xxx for 'login' (e.g. if the login is sample@cspace.berkeley.edu, set 'login': sample)
	- Set the 'server' variable to "" for prod or "-dev" for dev
	- The sample_environments.yml file is just an example page of how the environments.yml would work. You will need to create the environments.yml in the same format but with credentials filled out

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

[Capybara](http://jnicklas.github.io/capybara/) is Ruby gem that drives a browser over the code to run these tests.

[Cucumber](http://cukes.info) is a tool that supports Behavior Driven Development and software testing. It uses the language, Gherkin, to understand user-readable files (features) and parse them into scenarios. These scenarios contain steps that are then matched to the step definitions written in Ruby. 

(Source: https://girliemangalo.wordpress.com/2012/10/29/introduction-to-cucumber/)

## IV. Running Tests Headless (Without Browser window opening)

There are currently two options for headless testing, and it depends on which operating system you are current using.

FOR LINUX:
To avoid using a browser window (aka headless testing), download the [capybara-webkit](https://github.com/thoughtbot/capybara-webkit) gem.

Set up a virtual X server (required by capybara-webkit) by either using the xvfb-run utility:
```ruby
xvfb-run -a bundle exec spec
```
Or following [these instructions](https://github.com/leonid-shevtsov/headless) to set up Xvfb / QI (** for Linux platforms only)

The capybara-webkit gem 
```ruby
sudo gem install capybara-webkit
```
Finally, uncomment lines 22 - 26 in features/support/env.rb to run cucumber headless.

FOR OS X:
First install phantomjs through their [website](https://code.google.com/p/phantomjs/downloads/list). Look for the macosx.zip and download and extract.

Alternatively you can use homebrew:
```ruby
brew install phantomjs
```
However it may take a long time as it will download the Qt library. It may be best to download qt beforehand using homebrew:
```ruby
brew install qt
```

Then install the [poltergeist](https://github.com/teampoltergeist/poltergeist) gem using ruby:
```ruby
sudo gem install poltergeist
```
Finally uncomment lines 34-39 in features/support/env.rb to run cucumber headless.

NB: There is a problem with the suggest tests failing on headless for Macs because phantomjs uses poltergeist instead of selenium. Also, it may have problems later on with other interactive javascript features that we have not tested yet. 

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
