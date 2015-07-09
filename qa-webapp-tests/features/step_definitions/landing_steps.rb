Then(/^I will sign in$/) do
    click_link('login') 
    fill_in "Username", :with => $a1 + $ginstitution + ".cspace.berkeley.edu"
    fill_in "Password", :with => $a2
    click_button "Sign In"
    visit 'https://webapps' + $server + '.cspace.berkeley.edu/' + $institution
end

Then(/^I will see all available webapps "(.*?)"$/) do |apps|
    for i in apps.split(', ')
        find_link(i).visible?
    end
end

# Only one of the 2 cases below should be used when the user signs out: 
Then(/^I see No apps$/) do
    page.should have_content("No apps")
end

Then(/^I see "(.*?)"$/) do |apps|
    for i in apps.split(', ')
        find_link(i).visible?
    end
end
