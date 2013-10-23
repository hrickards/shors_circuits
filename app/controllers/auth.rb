# Controller for omniauth authentication
Quantum::App.controllers :auth do
  # TODO TODO TODO TODO TODO
  # Change this --- we don't want to enable csrf
  set :protect_from_csrf, false
  set :allow_disabled_csrf, false

  # Called after a successful developer-protocol (ie just entering name
  # and email address) login
  post :developer_callback, :map => '/auth/developer/callback' do
    omniauth = request.env["omniauth.auth"]

    # Create new user from ommiauth info if one doesn't exist
    @user = User.find_by_uid omniauth['uid']
    @user = User.new_from_omniauth omniauth if @user.nil?

    # Save user id to session
    session[:uid] = omniauth['uid']

    # Redirect to home
    redirect_to url_for(:pages, :home)
  end

  # Signout
  get :signout, :map => 'auth/signout' do
    # Remove user id from session
    session[:uid] = nil

    # Redirect to home
    redirect_to url_for(:pages, :home)
  end
end
