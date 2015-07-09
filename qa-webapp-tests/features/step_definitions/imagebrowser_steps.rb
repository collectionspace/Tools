When(/^I search for "([^"]*)" and enter "([^"]*)"$/) do |query1, query2|
    fill_in "text", :with => query1
    fill_in "maxresults", :with => query2
    click_button "Search"
end

Then(/^I see "([^"]*)" objects out of however many there are$/) do |arg1|
    page.should have_content(arg1.to_s + " objects")
end

When(/^I click on musueum number "([^"]*)"$/) do |arg1|
    #click_link(arg1) does not work due to another page opening
    visit 'https://webapps' + $gserver + '.cspace.berkeley.edu/' + $ginstitution + '/search/search/?displayType=full&maxresults=1&resultsOnly=True&text=%22'+ arg1.to_s + '%22'
end

Then(/^I see a page with these headers "([^"]*)"$/) do |headers|
    header_lst = headers.split(', ')
    header_lst.each do |header|
        page.should have_content(header)
    end
end

When(/^I click on Facets Tab$/) do
    click_link('Facets') 
    page.should have_table("Facet.name")
end

Then(/^I see a table with (\d+) headers "([^"]*)" and (\d+) cols "([^"]*)"$/) do |numHeaders, headers, numCols, cols|
    headers_list = headers.split(', ')
    for h in headers_list
        find('tr', text: h).should have_content(h)
    end 
    col_lst = cols.split(', ')
    for c in col_lst
        all('tr', text: c, :between => 7..12)[0].should have_content(c)
    end 
end
