$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'provider_taxonomy/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'provider_taxonomy'
  s.version     = ProviderTaxonomy::VERSION
  s.authors     = ['ClydeDroid']
  s.email       = ['clydedroid@gmail.com']
  s.homepage    = 'https://github.com/adhocteam/provider-taxonomy'
  s.summary     = 'A gem to add a database table containing the NUCC Provider Taxonomy'
  s.description = 'A gem to add a database table containing the NUCC Health Care Provider Taxonomy'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rails'

  s.add_development_dependency 'pg'
end
