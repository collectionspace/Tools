Then(/^I will enter "(.*?)" "(.*?)" in the "(.*?)" field$/) do |type, query, button|
    fill_in type, :with => query
    find(:link_or_button, button).click
end

Then(/^I verify a page only listing images$/) do
    # Screenshot appears; please verify the results of the Search for Images.
    screenshot_and_open_image
end
