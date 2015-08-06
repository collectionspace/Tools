When(/^I enter "([^"]*)" in the "([^"]*)" field$/) do |query, field|
    fill_in field, :with => query
end

Then(/^I click on "([^"]*)" in the dropdown menu and search$/) do |query|
    sleep(5)
    page.find('li', :text => query).click
  
    click_button "Search"
end

Then(/^I find "([^"]*)" in "([^"]*)" field$/) do |query, field|
  page.should have_table('resultsListing')
  @table = page.all('#resultsListing tr')
  index = 0
    @table.each do |tr|
      next unless index != 0
    tr.should have_text(query)
    index += 1
  end
end