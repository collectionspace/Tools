Then(/^I will sign in$/) do
    fill_in "Username", :with => env_config['login'] + "@" + $ginstitution + ".cspace.berkeley.edu"
    fill_in "Password", :with => env_config['password']
    click_button "Sign In"
end

Then(/^I see "(.*?)"$/) do |apps|
    for app in apps.split(', ')
        find_link(app).visible?
    end
end