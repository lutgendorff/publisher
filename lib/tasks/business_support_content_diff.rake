namespace :business_support_content_diff do
  desc "Compares the CSV data to publisher data."
  task :diff => :environment do
    BusinessSupportContentDiff.new.diff
  end

  desc "Reports differences between import data and publisher content in a CSV."
  task :report => :environment do
    BusinessSupportContentDiff.new.report
  end
end
