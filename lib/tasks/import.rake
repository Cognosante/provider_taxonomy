namespace :provider_taxonomy do
  desc 'Run all import tasks'
  task import: [:import_provider_taxonomy, :import_categories, :import_institution_taxonomy] do
    puts 'Ready to go!'
  end

  desc 'Import data representing provider specialties taxonomy. Result is db table with parent ids and depth for each entry.'
  task import_provider_taxonomy: :environment do
    require 'csv'
    require 'open-uri'

    def download(url, dest)
      retry_count = 10
      begin
        open(url) do |u|
          f = File.open(dest, 'wb')
          f.write(u.read)
          f.close
        end
      rescue SocketError
        retry_count -= 1
        if retry_count > 0
          sleep(1.0)
          retry
        else
          raise
        end
      end

      if File.exist?(dest)
        puts "Taxonomy file downloaded from: #{url}"
      else
        sleep(1.0)
        if File.exist?(dest)
          puts "Taxonomy file downloaded from: #{url}"
        else
          puts "Taxonomy file FAILED TO DOWNLOAD from: #{url}"
        end
      end
    end

    table = 'taxonomy_items'
    $stdout.sync = true
    print "Truncating and resetting the " + table + " table\n"
    ActiveRecord::Base.connection.execute("TRUNCATE " + table + " RESTART IDENTITY;")

    today = Date.today
    if today.month < 7
      current_version = today.year.to_s[2, 2] + "0"
      previous_version = (today.year - 1).to_s[2, 2] + "1"
    else
      current_version = today.year.to_s[2, 2] + "1"
      previous_version = today.year.to_s[2, 2] + "0"
    end

    begin
      if Dir.exists?('db/provider_taxonomy')
        old_file = Dir['db/provider_taxonomy/nucc_taxonomy_*.csv'][0]
        File.delete(old_file) if old_file
      else
        FileUtils.mkdir_p 'db/provider_taxonomy'
      end
      taxonomy_file = "db/provider_taxonomy/nucc_taxonomy_#{current_version}.csv"
      download_file = "http://nucc.org/images/stories/CSV/nucc_taxonomy_#{current_version}.csv"
      download(download_file, taxonomy_file)
    rescue OpenURI::HTTPError
      taxonomy_file = "db/rawdata/CMS_Taxonomy_Hierarchy/nucc_taxonomy_#{previous_version}.csv"
      download_file = "http://nucc.org/images/stories/CSV/nucc_taxonomy_#{previous_version}.csv"
      download(download_file, taxonomy_file)
    end

    csv_text = File.read(taxonomy_file).scrub
    csv = CSV.parse(csv_text, headers: true)

    print "Importing provider taxonomy\n"
    csv.each_with_index do |row, i|
      print "\n" if (i % 80).zero?
      print "."

      grouping = TaxonomyItem.where(name: row['Grouping'], depth: 1).first
      if !grouping
        grouping = TaxonomyItem.create!(
          name: row['Grouping'],
          depth: 1,
          parent_id: nil,
          taxonomy_code: nil
        )
      end

      if row['Specialization'].blank?
        classification = TaxonomyItem.where(name: row['Classification'], depth: 2, parent_id: grouping.id).first
        if classification
          classification.update_attributes(
            taxonomy_code: row['Code'],
            definition: row['Definition'],
            notes: row['Notes']
          )
        else
          TaxonomyItem.create!(
            name: row['Classification'],
            depth: 2,
            parent_id: grouping.id,
            taxonomy_code: row['Code'],
            definition: row['Definition'],
            notes: row['Notes']
          )
        end
      else
        classification = TaxonomyItem.where(name: row['Classification'], parent_id: grouping.id, depth: 2).first
        if !classification
          classification = TaxonomyItem.create!(
            name: row['Classification'],
            depth: 2,
            parent_id: grouping.id,
            taxonomy_code: nil,
            definition: nil,
            notes: nil
          )
        end

        TaxonomyItem.create!(
          name: row['Specialization'],
          depth: 3,
          parent_id: classification.id,
          taxonomy_code: row['Code'],
          definition: row['Definition'],
          notes: row['Notes']
        ).id
      end
    end
    print "\n"
    puts 'Provider taxonomy imported.'
    FileUtils.rm_rf 'db/provider_taxonomy'
  end

  desc 'Import provider type specialties categories.'
  task import_categories: :environment do
    INDIVIDUAL_SPECIALTIES = [
      'Allopathic & Osteopathic Physicians',
      'Behavioral Health & Social Service Providers',
      'Chiropractic Providers',
      'Dental Providers',
      'Dietary & Nutritional Service Providers',
      'Emergency Medical Service Providers',
      'Eye and Vision Services Providers',
      'Nursing Service Providers',
      'Nursing Service Related Providers',
      'Other Service Providers',
      'Pharmacy Service Providers',
      'Physician Assistants & Advanced Practice Nursing Providers',
      'Podiatric Medicine & Surgery Service Providers',
      'Respiratory, Developmental, Rehabilitative and Restorative Service Providers',
      'Speech, Language and Hearing Service Providers',
      'Student, Health Care',
      'Technologists, Technicians & Other Technical Service Providers'
    ].freeze

    GROUP_SPECIALTIES = ['Group'].freeze

    INSTITUTIONAL_SPECIALTIES = [
      'Agencies',
      'Ambulatory Health Care Facilities',
      'Hospital Units',
      'Hospitals',
      'Laboratories',
      'Managed Care Organizations',
      'Nursing & Custodial Care Facilities',
      'Other Service Providers',
      'Residential Treatment Facilities',
      'Respite Care Facility',
      'Transportation Services'
    ].freeze

    SUPPLIER_SPECIALTIES = [
      'Suppliers'
    ].freeze

    if ActiveRecord::Base.connection.table_exists? 'taxonomy_items'

      print "Importing provider type specialty categories\n"
      provider_types = TaxonomyItem.provider_types

      INDIVIDUAL_SPECIALTIES.each do |specialty|
        s = TaxonomyItem.find(provider_types.where(name: specialty).first.id)
        s.update_attributes(category: s.category = 'individual')
        print "."
      end

      GROUP_SPECIALTIES.each do |specialty|
        s = TaxonomyItem.find(provider_types.where(name: specialty).first.id)
        s.update_attributes(category: s.category = 'group')
        print "."
      end

      INSTITUTIONAL_SPECIALTIES.each do |specialty|
        s = TaxonomyItem.find(provider_types.where(name: specialty).first.id)
        s.update_attributes(category: s.category = 'institution')
        print "."
      end

      SUPPLIER_SPECIALTIES.each do |specialty|
        s = TaxonomyItem.find(provider_types.where(name: specialty).first.id)
        s.update_attributes(category: s.category = 'supplier')
        print "."
      end

      print "\n"

    else
      print "The 'taxonomy_items' table does not exist. Be sure to create it first."
    end
  end

  desc 'Import data representing institution specialties taxonomy. '
  task import_institution_taxonomy: :environment do
    require 'csv'

    table = 'taxonomy_items'

    $stdout.sync = true

    if ActiveRecord::Base.connection.table_exists? table

      csv_text = File.read(ProviderTaxonomy::Engine.root + 'db/institution_types.csv')
      csv = CSV.parse(csv_text, :headers => true)

      existing_institution_types = TaxonomyItem.where(category: 'institution')

      print "Importing institution taxonomy\n"
      csv.each_with_index do |row, i|

        print "\n" if i % 80 == 0

        if !existing_institution_types.exists?(name: row['Name'], sub_category: row['Sub-Category'])

          # Create this type
          TaxonomyItem.create!(
            name: row['Name'],
            category: row['Category'],
            sub_category: row['Sub-Category'],
            ).id
          print "*"
        end
        print "."
      end
      print "\n"
    else
      print "The #{table} table does not exist. Please create it first."
    end
  end
end
