Then(/^I will click the "(.*?)" button$/) do |button|
	click_on(button)
end

Then(/^I will select a file "(.*?)" to upload$/) do |f|
	@file = File.expand_path(f)
	attach_file 'imagefiles', @file
end

Then(/^I will click the (\d+) "([^"]*)"$/) do |index, arg2|
  all("input[type='submit']")[index.to_i-1].click
  page.has_content?("enqueued; 1 images.")
end

