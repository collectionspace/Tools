Given(/^I am on the "(.*?)" homepage$/) do |institution|
    $ginstitution = institution
    visit 'https://webapps' + env_config['server'] + '.cspace.berkeley.edu/' + institution
end

Then(/^I will sign in$/) do
    fill_in "Username", :with => env_config['login'] + "@" + $ginstitution + ".cspace.berkeley.edu"
    fill_in "Password", :with => env_config['password']
    find(:link_or_button, "Sign In").click
end

Then(/^I see "(.*?)" in "(.*?)"$/) do |items, div|
    within(div) do
        for item in items.split(', ')
            find_link(item).visible?
        end
    end
end