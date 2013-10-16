# Global project settings
Padrino.configure_apps do
  # enable :sessions
  set :session_secret, '84deae3c791d89d4f517bfb8fed06989710b37ad829d66db2a51035456c7d9db'
  set :protection, true
  set :protect_from_csrf, true
end

# Mounts the core application for this project
Padrino.mount('Quantum::App', :app_file => Padrino.root('app/app.rb')).to('/')
