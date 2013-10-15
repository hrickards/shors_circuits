Quantum::App.controllers :auth do
  # TODO TODO TODO TODO TODO
  # Change this
  set :protect_from_csrf, false
  set :allow_disabled_csrf, false
  post :developer_callback, :map => '/auth/developer/callback' do
    omniauth = request.env["omniauth.auth"]

    @user = User.find_by_uid omniauth['uid']
    @user = User.new_from_omniauth omniauth if @user.nil?

    session[:uid] = omniauth['uid']

    redirect_to url_for(:pages, :home)
  end

  get :signout, :map => 'auth/signout' do
    session[:uid] = nil
    redirect_to url_for(:pages, :home)
  end
end
