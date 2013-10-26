Quantum::App.helpers do
  def signed_in?
    !session[:uid].nil?
  end

  def current_user
    signed_in? and User.find_by_uid session[:uid]
  end

  def require_sign_in
    unless signed_in?
      flash[:error] = "You need to be signed in to do that!"
      redirect_to url_for(:pages, :home)
    end
  end
end
