Given(/^I am on the "(.*?)" homepage$/) do |institution|
    $ginstitution = institution
    visit 'https://webapps' + env_config['server'] + '.cspace.berkeley.edu/' + institution
end

Then(/^I check for "(.*?)"$/) do |arg1|
    expect(page).to have_css("img[src*='" + arg1 + "']")
end

Then(/^I will click the "(.*?)" feature$/) do |feature|
    find_link(feature).visible?
    click_link(feature)
end

When(/^I enter "(.*?)" in the Keyword "(.*?)" and click "(.*?)"$/) do |query, field, button|
    fill_in field, :with => query
    click_button button
end

Then(/^I verify the search fields "(.*?)" in "(.*?)"$/) do |field, range|
    fields = field.split(', ')
    within(range) do
        for i in fields
            find('label', text: i).has_content? i
        end
    end
end

Transform /^(-?\d+)$/ do |number| # transforms string to int, source: https://github.com/cucumber/cucumber/wiki/Step-Argument-Transforms
    number.to_i
end

Then(/^I see a table with (\d+) headers "(.*?)" and (\d+) rows "(.*?)"$/) do |numheaders, headers, numrows, rows| 
    within('div#resultsPanel') do
        has_css?('resultsListing')
        @table = all('#resultsListing tr')
        for h in headers.split(', ') do
            @table[0].has_content?(h)
        end 
        j = 0
        row_lst = rows.split(', ')
        while j < numrows
            @table[j + 1].has_content?(row_lst[j])
            j += 1
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
        sleep(5)
        screenshot_and_open_image
        find_link('prev').click
    end
end

Then (/^I click the button "(.*?)" and download the csv file$/) do |button|
    click_button(button)
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
    expect(find_field(field).value).to eq val
end

Then(/^I see two buttons$/) do
    expect(page).to have_selector(:link_or_button, 'map-bmapper' || 'map selected with Berkeley Mapper')
    expect(page).to have_selector(:link_or_button, 'map-google' || 'map selected with Google staticmaps API')
end
    
# Inconsistent, works sometimes, doesn't work other times.    
Then(/^I find the content "(.*?)" in "(.*?)"$/) do |content, section|
    within(first(section)) do
        page.has_content?(content)
    end
end

Then(/^the url contains "([^"]*)"$/) do |url|
    sleep(5)
    new_window = window_opened_by { click_button 'map selected with Berkeley Mapper'}
    within_window(new_window) do
        actual = URI.parse(current_url).path
        actual.include?("berkeleymapper.berkeley.edu/")
        page.has_content?("pointDisplayValue")  
        expect(page).to have_content("Click on MarkerClusters or draw a polygon to query points") 
        screenshot_and_open_image
    end
    if Capybara.current_driver == :poltergeist
        page.driver.browser.switch_to_window(page.driver.browser.window_handles[0])
    else 
        page.driver.browser.switch_to.window(page.driver.browser.window_handles[0])
    end
end 

Then(/^I will select "([^"]*)" under Select field to summarize on$/) do |field|
    click_link('Statistics')
    select(field, :from => 'summarizeon')
    click_button("Display Summary")
    expect(page).to have_table('statsListing')
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

And(/^I verify the contents of the page$/) do 
    # Screenshot appears; please verify the results are in Full display
    screenshot_and_open_image
end

Then(/^I mark the checkboxes "(.*?)"$/) do |boxes|
    for box in boxes.split(', ')
        page.check(box)
        page.uncheck(box) 
    end
end

When(/^I go back$/) do 
    page.evaluate_script('window.history.back()')
end 