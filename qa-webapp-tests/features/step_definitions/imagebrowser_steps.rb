When(/^I search for "([^"]*)" in "([^"]*)" and enter "([^"]*)"$/) do |query, label, text|
    fill_in label, :with => query
    fill_in "maxresults", :with => text
    find(:link_or_button, "Search").click
end

Then(/^I see a page with these headers "([^"]*)"$/) do |headers|
    headers.split(', ').each do |header|
        page.all(header).any?
    end
end

Then(/^I see a table with (\d+) headers "([^"]*)" and (\d+) cols "([^"]*)"$/) do |numHeaders, headers, numCols, cols|
    for header in headers.split(', ')
        find('tr', text: header).should have_content(header)
    end 
    for col in cols.split(', ')
        all('tr', text: col, :between => 3..10)[0].should have_content(col)
    end 
end