Given(/^I am on the "(.*?)" homepage for "(.*?)"$/) do |institution, server|
    $ginstitution = institution
    $gserver = server
    visit 'https://webapps' + server + '.cspace.berkeley.edu/' + institution
    click_link('login') 

    fill_in "Username", :with => env_config['login'] + "@" + $ginstitution + ".cspace.berkeley.edu"
    fill_in "Password", :with => env_config['password']

    click_button "Sign In"
    visit 'https://webapps' + server + '.cspace.berkeley.edu/' + institution
end

Then(/^I will click the "(.*?)" feature$/) do |feature|
    find_link(feature).visible?
    click_link(feature)
end

When(/^I enter "(.*?)" in the Keyword "(.*?)" and click "(.*?)"$/) do |query, field, button|
    fill_in field, :with => query
    click_button button
end

Transform /^(-?\d+)$/ do |number| # transforms string to int, source: https://github.com/cucumber/cucumber/wiki/Step-Argument-Transforms
    number.to_i
end

Then(/^I see a table with (\d+) headers "(.*?)" and (\d+) rows "(.*?)"$/) do |numheaders, headers, numrows, rows| 
    within('div#results') do
        has_css?('resultsListing')
        @table = all('#resultsListing tr')
        headers_lst = headers.split(', ')
        index = 0
        while index < numheaders do
            @table[0].has_content?(headers_lst[index])
            index += 1
        end 

        index = 0
        row_lst = rows.split(', ')
        while index < numrows
            @table[index + 1].has_content?(row_lst[index])
            index += 1
        end
    end
end

# Problem: doesn't seem to actually identify and click the up and down arrows
Then(/^I will click the up and down arrows beside the headers$/)  do
    page.all("tablesorter-headerRow").each do |arrow|
        arrow.click
    end
end

Then(/^I will click the arrows to toggle between pages$/) do
    within("div#searchfieldsTarget") do
        find_link('next').click
        screenshot_and_open_image
        find_link('prev').click
    end
end

Then (/^I click the button "(.*?)" and download the csv file$/) do |button|
    click_button(button)
end 

When(/^I click the "(.*?)" tab$/) do |tab|
    click_link(tab)
end

Then(/^I see the headers "([^"]*)"$/) do |headers| 
    within("div#facets") do
        headers = headers.split(', ')
        for h in headers
            find('th', text: h).has_content?(h)
        end 
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
    page.should have_selector(:link_or_button, 'map selected with Berkeley Mapper')
    page.should have_selector(:link_or_button, 'map selected with Google staticmaps API')
end

When(/^I click the "(.*?)" button$/) do |button|
    find(:link_or_button, button).click
end
    
Then(/^I find the content "(.*?)"$/) do |content|
    within(first("div#maps")) do
        has_content?(content)
    end
end
    
Then(/^the url contains "([^"]*)"$/) do |url|
    # switch_to_new_pop_up  
    new_window = page.driver.browser.window_handles.last 
    page.within_window new_window do
        actual = URI.parse(current_url).path
        actual.include?("berkeleymapper.berkeley.edu/")
        page.has_content?("pointDisplayValue")  
        screenshot_and_open_image
    end
    page.driver.browser.switch_to.window(page.driver.browser.window_handles[0])
end 

Then(/^I will select "([^"]*)" under Select field to summarize on$/) do |field|
    select(field, :from => 'summarizeon')
    click_button("Display Summary")
    page.should have_table('statsListing')
end

Then(/^I will see a table with the headers "([^"]*)"$/) do |headers|
    headers = headers.split(', ')
    for h in headers
        find('th', text: h).has_content?(h)
    end
end

Then(/^I will click "(.*?)" and the "([^"]*)" field should have "([^"]*)"$/) do |button, field, result|
    click_button(button)
    page.has_field?(field, :with => result)
end

Then(/^I verify the contents of the page$/) do 
    # Screenshot appears; please verify the results are in Full display
    screenshot_and_open_image
end

Then(/^I will click the publicsearch feature$/) do
  #click_link('publicsearch')
  visit 'https://webapps' + $gserver + '.cspace.berkeley.edu/' + $ginstitution + "/publicsearch/publicsearch"
end