# Provider Taxonomy
A gem to add a database table containing the NUCC Health Care Provider Taxonomy.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'provider_taxonomy'
```

And then execute:
```bash
$ bundle install
```

Finally, run the migration and rake task:
```bash
$ rake db:migrate
```
```bash
$ rake provider_taxonomy:import
```

## Usage
Once installed, your Rails app will have a `taxonomy_items` database table and a `TaxonomyItem` model from which you can access all healthcare provider specialties.

If you would like to extend the model with your own, you can do the following

```ruby
class Specialty < TaxonomyItem
  self.table_name = "taxonomy_items"
  belongs_to :parent, foreign_key: :parent_id, class_name: Specialty, required: false
  # Your code goes here
end
```

You may also wish to add the following to `db/seeds.rb`:

```ruby
Rake::Task['provider_taxonomy:import'].invoke
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
