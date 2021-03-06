namespace :business_support_content do
  desc "Imports Imminence facet data into the corresponding BusinessSupportEdition"
  task :import_facet_data => :environment do
    BusinessSupportFacetDataImporter.run
  end

  desc "Migrates locations slugs into Mapit area ids"
  task :migrate_locations_to_areas => :environment do
    BusinessSupportLocationMigrator.run
  end
end
