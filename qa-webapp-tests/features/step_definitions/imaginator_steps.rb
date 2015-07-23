Then(/^I will enter "(.*?)" in the Search the Metadata field$/) do |query|
    fill_in "text", :with => query
    click_button "Search the Metadata"
end

Then(/^I will select the item "([^"]*)" and results displayed include the following "([^"]*)"$/) do |item, info|
    click_link(item)
    info_list = info.split(", ")
    info_list.each do |arg| 
        page.has_content?(arg)
    end
end

When(/^I enter "([^"]*)" in the Search for Images$/) do |query|
    fill_in "text", :with => query
    click_button "Search for Images"
end

Then(/^I see page only listing images$/) do
    # Screenshot appears; please verify the results of the Search for Images.
    screenshot_and_open_image
end

When(/^I click an image with "([^"]*)"$/) do |id|
    visit 'https://webapps' + $gserver + '.cspace.berkeley.edu/' + $ginstitution + "/imaginator?maxresults=1&displayType=full&" + id
end