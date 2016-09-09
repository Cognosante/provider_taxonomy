namespace :provider_taxonomy do
  desc 'Import data representing provider specialties taxonomy. Result is db table with parent ids and depth for each entry.'
  task import: :environment do
    require 'csv'
    require 'open-uri'

    def download(url, dest)
      open(url) do |u|
        File.open(dest, 'wb') { |f| f.write(u.read) }
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
      download("http://nucc.org/images/stories/CSV/nucc_taxonomy_#{current_version}.csv", taxonomy_file)
      if File.exist?(taxonomy_file)
        puts "Taxonomy file downloaded: Version #{current_version}."
      end
    rescue OpenURI::HTTPError
      taxonomy_file = "db/rawdata/CMS_Taxonomy_Hierarchy/nucc_taxonomy_#{previous_version}.csv"
      download("http://nucc.org/images/stories/CSV/nucc_taxonomy_#{previous_version}.csv", taxonomy_file)
      if File.exist?(taxonomy_file)
        puts "Taxonomy file downloaded: Version #{previous_version}."
      end
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
end
