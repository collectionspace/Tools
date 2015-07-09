Then(/^I select a report called "([^"]*)"$/) do |report|
    click_link(report)
end

Then(/^I will see the correct report in pdf format$/) do 
    # Screenshot appears; please verify the results of the Search for Images.
    screenshot_and_open_image
end

When(/^I click "([^"]*)"$/) do |button|
    click_button(button)
end

Then(/^I will see a list of reports as follows "([^"]*)" and files "([^"]*)"$/) do |reports, files|
    for report in reports.split(", ")
      find_link(report).visible?
    end

    for file in files.split(", ")
      page.has_content?(file)
    end
end

Then(/^sign out$/) do
    click_link("logout")
    #problem with logging out, some institutions redirect to landing, some just to institution
    current_url.should have_content('https://webapps' + $gserver + '.cspace.berkeley.edu/' + $ginstitution)
end

