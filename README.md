# ProviderTaxonomy
A gem to add a database table containing the NUCC Health Care Provider Taxonomy.

## Usage
Once installed, your Rails app will have a TaxonomyItem database table, from which you can access all healthcare provider specialties.

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

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
