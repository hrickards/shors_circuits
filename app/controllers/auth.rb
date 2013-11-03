# Controller for omniauth authentication
Quantum::App.controllers :auth do
  # Called after a successful login
  callback = lambda do
    omniauth = request.env["omniauth.auth"]

    if session[:uid]
      # If user is currently signed in, add new authorization to the
      # user
      User.find_by_uid(session[:uid]).add_provider(omniauth)

      # Redirect to home
      humanised = omniauth["provider"] == :open_id ? "Open ID" : omniauth["provider"].capitalize
      flash[:notice] =
        "You can now login using #{humanised}."
      redirect_to request.env['omniauth.origin'] || url_for(:pages, :home)
    else
      # Otherwise find existing user or create one if one doesn't exist
      @user = User.find_or_create omniauth

      # Save user id to session
      session[:uid] = @user.uid

      # Redirect to home
      flash[:notice] = "Successfully logged in."
      redirect_to request.env['omniauth.origin'] || url_for(:pages, :home)
    end

    # Create new user from ommiauth info if one doesn't exist
    @user = User.find_by_uid_and_provider omniauth['uid'], omniauth["provider"]
    @user = User.new_from_omniauth omniauth if @user.nil?
  end
  # Run on post & get. SO 8414395
  post :callback, :map => '/auth/:provider/callback', &callback
  get :callback, :map => '/auth/:provider/callback', &callback

  # Signout
  get :signout, :map => 'auth/signout' do
    require_sign_in

    # Remove user id from session
    session[:uid] = nil

    # Redirect to home
    flash[:notice] = "Successfully logged out."
    redirect_to url_for(:pages, :home)
  end

  # Called after a failed login
  failure = lambda do
    # Redirect back home
    flash[:error] = "Authentication error!"
    redirect_to url_for(:pages, :home)
  end
  post :failure, :map => '/auth/failure', &failure
  get :failure, :map => '/auth/failure', &failure
end
