require 'yaml'
require 'openid/store/filesystem'

module Quantum
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers
    register Padrino::Sprockets

    sprockets minify: (Padrino.env == :production)

    enable :sessions
    
    # Open YAML config
    config = YAML.load_file('config/application.yml')[ENV["PADRINO_ENV"]]

    # use Rack::Session::Cookie
 
    # use OmniAuth::Strategies::Developer
    use OmniAuth::Builder do
      provider :google_oauth2, config["GOOGLE_ID"], config["GOOGLE_SECRET"],
        {
          name: "google"
        }
      provider :github, config["GITHUB_ID"], config["GITHUB_SECRET"]
      provider :twitter, config["TWITTER_ID"], config["TWITTER_SECRET"]
      provider :facebook, config["FACEBOOK_ID"], config["FACEBOOK_SECRET"]
      provider :open_id, :store => OpenID::Store::Filesystem.new('/tmp')
    end

    if Padrino.env == :production
      # Rate limiting for running circuits
      use Rack::Throttle::IntervalRuns, :min => 10.0 # max 1 request per 10 seconds
      use Rack::Throttle::HourlyRuns, :max => 100 # max 100 requests per hour
    end

    ##
    # Caching support
    #
    register Padrino::Cache
    enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    # set :cache, Padrino::Cache::Store::Memory.new(50)
    # set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    # You can manage errors like:
    #
    #   error 404 do
    #     render 'errors/404'
    #   end
    #
    #   error 505 do
    #     render 'errors/505'
    #   end
    #
  end
end
