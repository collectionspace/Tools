Then(/^I will enter "(.*?)" in the Search field$/) do |query|
    fill_in "kw", :with => query
    click_button "Search"
end

Then(/^the results displayed include "([^"]*)"$/) do |info|
    info_list = info.split(", ")
    info_list.each do |arg| 
        page.should have_content(arg)
    end
end

Then(/^I see the three rows "([^"]*)"$/) do |rows|
    index = 0
    row_lst = rows.split(', ')
    while index < 3
        page.should have_content(row_lst[index])
        index += 1
    end
end

Then(/^I should see page only listing images and museum number and object name\.$/) do
    # Screenshot appears; please verify information displayed.
    screenshot_and_open_image
end

Then(/^I will click on "([^"]*)" and redirect to the homepage to see "([^"]*)"$/) do |eloanNum, apps|
    click_link(eloanNum) 
    for i in apps.split(', ')
      find_link(i).visible?
    end
end
