Quantum::App.helpers do
  def signed_in?
    !session[:uid].nil?
  end

  def current_user
    signed_in? and User.find_by_uid session[:uid]
  end
end
