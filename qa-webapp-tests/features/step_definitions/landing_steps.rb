Then(/^I will sign in$/) do
    click_link('login') 
    
    # If you have user credentials, replace env_config['login'] and env_config['password'] with them 
    fill_in "Username", :with => env_config['login'] + "@" + $ginstitution + ".cspace.berkeley.edu"
    fill_in "Password", :with => env_config['password']
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
    page.has_content?("No apps")
end

Then(/^I see "(.*?)"$/) do |apps|
    for i in apps.split(', ')
        find_link(i).visible?
    end
end
