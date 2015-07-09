When(/^I enter "([^"]*)" in Culture field$/) do |query|
    fill_in "culturetree", :with => query
end

Then(/^I should find Chinese in the dropdown menu\.$/) do
  within("ul#ui-id-4") do 
      page.find('li', :text => 'Chinese')
    end
end

When(/^I click on "([^"]*)" and search$/) do |query|
  within("ul#ui-id-4") do 
      page.find('li', :text => 'Chinese').click
    end
    click_button "Search"
end

Then(/^I should find "([^"]*)" in Culture field$/) do |query|
  page.should have_table('resultsListing')
  @table = page.all('#resultsListing tr')
  index = 0
    @table.each do |tr|
      next unless index != 0
    tr.should have_text(query)
    index += 1
  end
end