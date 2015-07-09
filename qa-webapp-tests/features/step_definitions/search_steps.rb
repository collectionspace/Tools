def switch_to_new_pop_up  
  page.driver.browser.switch_to.window
   (page.driver.browser.window_handles.last)
end

def close_active_window
 page.driver.browser.close  
 page.driver.browser.switch_to.window
   (page.driver.browser.window_handles[0])
end

Given(/^I am on the "(.*?)" homepage for "(.*?)"$/) do |institution, server|
    $ginstitution = institution
    $gserver = server
    visit 'https://webapps' + server + '.cspace.berkeley.edu/' + institution
    click_link('login') 
    # If you have user credentials, replace $a1 and $a2 with them 
    fill_in "Username", :with => $a1 + institution + ".cspace.berkeley.edu"
    fill_in "Password", :with => $a2

    click_button "Sign In"
    visit 'https://webapps' + server + '.cspace.berkeley.edu/' + institution
end

Then(/^I will click the "(.*?)" feature$/) do |feature|
    # click_link(feature)

    # Comment out the line below ONLY if the mounting point is fixed.
    visit 'https://webapps' + $gserver + '.cspace.berkeley.edu/' + $ginstitution + "/" + feature
end

When(/^I enter "(.*?)" in the Keyword "(.*?)" and click "(.*?)"$/) do |query, field, button|
    fill_in field, :with => query
    click_button button
end

Transform /^(-?\d+)$/ do |number| # transforms string to int, source: https://github.com/cucumber/cucumber/wiki/Step-Argument-Transforms
    number.to_i
end

Then(/^I see a table with (\d+) headers "(.*?)" and (\d+) rows "(.*?)"$/) do |numheaders, headers, numrows, rows| 
    page.should have_table('resultsListing')
    @table = page.all('#resultsListing tr')
    headers_lst = headers.split(', ')
    index = 0
    while index < numheaders do
        @table[0].should have_text(headers_lst[index])
        index += 1
    end 

    index = 0
    row_lst = rows.split(', ')
    while index < numrows
        @table[index + 1].should have_text(row_lst[index])
        index += 1
    end
end

# Problem: desn't seem to actually identify and click the up and down arrows
Then(/^I will click the up and down arrows beside the headers$/) do
    page.all("tablesorter-headerRow").each do |arrow|
        arrow.click
        screenshot_and_open_image
    end
end

Then (/^I download the csv file$/) do
    click_button "download selected as csv"
end 

When(/^I click the Facets tab$/) do
    click_link('Facets') 
end

Then(/^I see the headers "([^"]*)"$/) do |headers|
    headers = headers.split(', ')
    for h in headers
        find('th', text: h).should have_content(h)
    end 
end

Then(/^I will click the up and down arrows beside the headers without knowing table name$/) do
    page.all("tablesorter-headerRow").each do |arrow|
        arrow.click
        screenshot_and_open_image
    end
end

Then(/^I will click on a value "([^"]*)" and see it appear in the field "([^"]*)"$/) do |val, field|
    click_link val
    find_field(field).value.should eq val
end

Then(/^I will click on the "([^"]*)" tab and see two buttons$/) do |arg1|
    click_link arg1
    page.should have_selector(:link_or_button, 'map-google')
    page.should have_selector(:link_or_button, 'map-bmapper')
end

When(/^I click the google map I see "([^"]*)"$/) do |arg1|
    find(:link_or_button, 'map-google').click
    page.has_content?(arg1)
end
When(/^I click the bmapper, the url contains "([^"]*)"$/) do |url|
    find(:link_or_button, 'map-bmapper').click
    # switch_to_new_pop_up  
    new_window=page.driver.browser.window_handles.last 
    page.within_window new_window do
        actual = URI.parse(current_url).path
        actual.include?("http://berkeleymapper.berkeley.edu/")
        page.has_content?("pointDisplayValue")  
        screenshot_and_open_image
    end
    page.driver.browser.switch_to.window(page.driver.browser.window_handles[0])
end 

When(/^I will click the Statistics tab$/) do
    click_link("Statistics")
end

Then(/^I will select "([^"]*)" under Select field to summarize on$/) do |field|
    select(field, :from => 'summarizeon')
    click_button("Display Summary")
    page.should have_table('statsListing')
end

Then(/^I will see a table with the headers "([^"]*)"$/) do |headers|
    headers = headers.split(', ')
    for h in headers
        find('th', text: h).should have_content(h)
    end
end

Then(/^I will click "([^"]*)" and the "([^"]*)" field should have "([^"]*)"$/) do |button, field, result|
    click_button(button)
    page.should have_field(field, :with => result)
end

Then(/^I will click the publicsearch feature$/) do
  #click_link('publicsearch')
  visit 'https://webapps' + $gserver + '.cspace.berkeley.edu/' + $ginstitution + "/publicsearch/publicsearch"
end

# Then(/^I will redirect to the bmapper url from earlier$/) do
#     visit 'http://berkeleymapper.berkeley.edu/index.html?ViewResults=tab&tabfile=https://webapps.cspace.berkeley.edu/bmapper/' + 
# end
