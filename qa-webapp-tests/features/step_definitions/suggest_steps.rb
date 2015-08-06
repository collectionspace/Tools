def fill_in_autocomplete(selector, value)
    page.execute_script "$('input##{selector}').focus().val('#{value}').keydown()"
end

def choose_autocomplete(text)
    expect(find('ul.ui-autocomplete')).to have_content(text)
    page.execute_script("$('.ui-menu-item:contains(\"#{text}\")').find('a').trigger('mouseenter').click()")
end

When(/^I enter "([^"]*)" in the "([^"]*)" field$/) do |query, field|
    fill_in_autocomplete(field, query)
end

Then(/^I click on "([^"]*)" in the dropdown menu and search$/) do |text|
    choose_autocomplete(text)
    click_button "Search"
    sleep(5)
end