Then(/^I select a report called "([^"]*)"$/) do |report|
    click_link(report)
end

Then(/^I will see the correct report in pdf format$/) do 
    # Screenshot appears; please verify the results of the Search for Images.
    screenshot_and_open_image
    page.evaluate_script('window.history.back()')
end

Then(/^I click "([^"]*)"$/) do |button|
    find(:link_or_button, button).click
end