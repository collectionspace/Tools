# CSpaceAutomatedTesting
This repository is for automated testing components written in Cucumber and Ruby, and using the Capybara library, Selenium driver, and other gems (e.g. rspec, capybara-screenshot).

To get started, install the latest versions of Ruby and Rails (to do this, refer to the Tools and Setting Up sections in http://www.gamesparks.com/blog/automated-testing-with-cucumber-and-capybara/)

Next, install the gem capybara-screenshot which automatically captures a screen shot for every test failure (refer to: https://github.com/mattheworiordan/capybara-screenshot) 

Finally, clone this repository in your local directory.

To run the Gherkin scripts in your terminal, make sure you're in the home directory and run
      
      cucumber features/[featurename].feature


