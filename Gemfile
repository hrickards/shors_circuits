source 'https://rubygems.org'

gem 'padrino', github: 'padrino/padrino-framework'    # Padrino Edge
gem 'oj'                                              # Faster JSON
gem 'rake'
gem 'rabl'                                            # JSON templating
gem 'coffee-script'                                   # CoffeeScript
gem 'omniauth'                                        # Authentication
gem 'improved-rack-throttle', 
  require: 'rack/throttle', 
  github: 'bensomers/improved-rack-throttle'          # Rate limiting

# Omniauth strategies
gem 'omniauth-google-oauth2'                          # Google
gem 'omniauth-github'                                 # Github
gem 'omniauth-openid'                                 # OpenID

# Templating & CSS
gem 'compass'
gem 'susy'
gem 'slim'
gem 'susy'

# Sprockets (cf asset pipeline)
gem 'padrino-sprockets'
gem 'sprockets-sass'
gem 'yui-compressor'
gem 'jsmin'

# Mongo
gem 'bson_ext', require: 'mongo'
gem 'mongo_mapper'

group :production do
  gem 'puma', require: false                          # Server
end

group :development do
  # Deployment scripts
  gem 'capistrano', '~>3.0.0', require: false
  gem 'capistrano-bundler', require: false
end
