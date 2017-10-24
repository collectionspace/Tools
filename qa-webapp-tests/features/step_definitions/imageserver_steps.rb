Then(/^I will click Grid and see a page of images\.$/) do
    check('pixonly')
    find(:link_or_button, "Grid").click
end

Then(/^I will click an image with id "(.*?)" and observe url contains imageserver$/) do |id|
    visit 'https://webapps' + env_config['server'] +'.cspace.berkeley.edu/' + $ginstitution + '/imageserver/blobs/' + id
    expect(current_url).to have_content('https://webapps' + env_config['server'] + '.cspace.berkeley.edu/' + $ginstitution + '/imageserver/')
    screenshot_and_open_image
end