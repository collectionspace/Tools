
Then(/^I will select a file "(.*?)" to upload$/) do |f|
	@file = File.expand_path(f)
	attach_file 'imagefiles', @file
end

When(/^I click the (\d+) "([^"]*)"$/) do |index, arg2|
  all("input[type='submit']")[index.to_i-1].click
  page.has_content?("enqueued; 1 images.")
end


# Add these lines below back to xxx_bmu.feature only if running on DEV
# Then I will select a file "test.jpg" to upload
# When I click the 1 "createmedia"
# Then I see a table with 7 headers "File Name, Object Number, File Size, Date Created, Creator, Contributor, Rights Holder" and 1 rows "test.jpg"
# Then I will select a file "test2.jpg" to upload
# When I click the 2 "uploadmedia"
# Then I see a table with 7 headers "File Name, Object Number, File Size, Date Created, Creator, Contributor, Rights Holder" and 1 rows "test2.jpg"