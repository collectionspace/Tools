Then(/^I will click the "(.*?)" button$/) do |button|
	click_on(button)
end


# User has to manually upload files
Then(/^I will select a file "([^"]*)" to upload$/) do |files|
  files = files.split(', ')
  for file in files
  	page.attach_file('imagefiles', file)
  end
end

Then(/^I see the file is uploaded$/) do
	page.has_content?("2 files selected.")
end

Then(/^I will click the (\d+) "([^"]*)"$/) do |index, arg2|
  all("input[type='submit']")[index.to_i-1].click
  page.has_content?("enqueued; 2 images.")
end

